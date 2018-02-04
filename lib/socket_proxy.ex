defmodule SocketProxy do
  @moduledoc """
  Convinience for testing multiple socket connections.

  When testing a `Phoenix.Channel` you might run into one of the following
  situations:

  * You want to make sure that a message is received on a specific user's socket
  * You want to terminate the transport process.

  If you ever found yourself in one of these situations this library might come
  in handy.

  When using the functions provided by `Phoenix.ChannelTest` to connect to a
  socket or join a channel the socket or channel will be linked to the pid of
  the test. The test process will receive all the `Phoenix.Socket.Message` and
  `Phoenix.Socket.Broadcast` that would otherwise pushed to the client.

  Unfortunately this way it is impossible to assert that a message was sent
  on a specific socket, nor is it possible to to realy close the socket because
  the `transport_pid` of the socket is the test itself.

  This is where `SocketProxy` comes in. It proxies the socket connection through
  a seperate process and tags the messages so that its origin can be asserted
  on.

  ## Example

      defmodule SocketProxyWeb.RoomChannelTest do
        use SocketProxyWeb.ChannelCase
        use SocketProxy

        alias SocketProxyWeb.RoomChannel
        alias SocketProxyWeb.UserSocket

        describe "using the pids as identifiers" do
          setup do
            {:ok, proxy_pid} = start_proxy()
            params = %{"name" => "alice"}
            {:ok, socket} = connect_proxy(proxy_pid, UserSocket, params)
            socket = subscribe_and_join_proxy!(socket, RoomChannel, "room:1")

            {:ok, proxy_pid: proxy_pid, proxy_socket: socket}
          end

          test "assertions on the socket", %{proxy_socket: socket} do
            assert_push_on socket, "msg", %{"body" => "Welcome alice!"}
            refute_push_on socket, "msg", %{"body" => "Get out of here!"}
            refute_broadcast_on socket, "shout", %{"body" => "Hello World!"}
          end

          test "assertions on the proxy's pid", %{proxy_pid: pid} do
            assert_push_on pid, "msg", %{"body" => "Welcome alice!"}
          end

          test "good old assert_receive", %{proxy_pid: pid} do
            assert_receive {^pid, %Phoenix.Socket.Message{
              payload: %{"body" => "Welcome alice!"}
            }}
          end

          test "pushing messages", %{proxy_socket: socket} do
            push(socket, "shout", %{"body" => "Hello World!"})
            assert_broadcast_on socket, "shout", %{"body" => "Hello World!"}
          end
        end

        describe "using custom identifiers" do
          setup do
            {:ok, proxy_pid} = start_proxy(:alice_socket)
            params = %{"name" => "alice"}
            {:ok, socket} = connect_proxy(proxy_pid, UserSocket, params)
            socket = subscribe_and_join_proxy!(socket, RoomChannel, "room:1")

            :ok
          end

          test "assertions on the custom identifier" do
            assert_push_on :alice_socket, "msg", %{"body" => "Welcome alice!"}
            refute_push_on :alice_socket, "msg", %{"body" => "Get out of here!"}
          end
        end
      end

  """

  alias SocketProxy.Proxy
  alias Phoenix.Socket
  alias Phoenix.Socket.Message
  alias Phoenix.Socket.Broadcast

  @doc """
  Starts a proxy. This must always be invoked first!
  It accepts an indentifier for the forwarded messages as argument.
  When no indentifier was provided it will use the pid proxy as identifier.
  """
  @spec start_proxy(term | nil) :: GenServer.on_start()
  def start_proxy(id \\ nil) do
    Proxy.start_link(id)
  end

  @doc """
  Subscribes and joins the socket to the channel and links it to the proxy.
  See `Phoenix.ChannelTest.subscribe_and_join/4` for further details.
  """
  @spec subscribe_and_join_proxy(Socket.t(), atom, String.t(), map) :: {:ok, Socket.t()}
  def subscribe_and_join_proxy(socket, channel, topic, params \\ %{}) do
    Proxy.subscribe_and_join(socket.transport_pid, [
      socket,
      channel,
      topic,
      params
    ])
  end

  @doc """
  Subscribes and joins the socket to the channel and links it to the proxy.
  See `Phoenix.ChannelTest.subscribe_and_join!/4` for further details.
  """
  @spec subscribe_and_join_proxy!(Socket.t(), atom, String.t(), map) :: Socket.t()
  def subscribe_and_join_proxy!(socket, channel, topic, params \\ %{}) do
    case subscribe_and_join_proxy(socket, channel, topic, params) do
      {:ok, _, socket} ->
        socket

      {:error, error} ->
        raise "could not join channel, got error: #{inspect(error)}"
    end
  end

  @doc false
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Establishes a socket connection. Basically the same thing as
  `Phoenix.ChanneText.connect/2` does but instead of binding the process
  to the test it binds to the proxy.
  """
  @spec connect_proxy(pid, atom, map) :: {:ok, Socket.t()}
  defmacro connect_proxy(pid, handler, params \\ %{}) do
    if endpoint = Module.get_attribute(__CALLER__.module, :endpoint) do
      quote do
        unquote(__MODULE__).__connect_proxy__(
          unquote(pid),
          unquote(endpoint),
          unquote(handler),
          unquote(params)
        )
      end
    else
      raise "module attribute @endpoint not set for connect_proxy/3"
    end
  end

  @doc false
  def __connect_proxy__(proxy_pid, endpoint, handler, params) do
    Proxy.connect(
      proxy_pid,
      endpoint,
      handler,
      params
    )
  end

  @doc """
  Asserts the channel has pushed a message back to the client on the given
  socket with the given event and payload within `timeout`.
  Works somilar to `Phoenix.ChannelTest.assert_push/2`.
  """
  defmacro assert_push_on(id_or_socket, event, payload, timeout \\ 100) do
    quote do
      pid_or_id = unquote(__MODULE__).__get_pid_or_id__(unquote(id_or_socket))

      assert_receive {
                       ^pid_or_id,
                       %Message{event: unquote(event), payload: unquote(payload)}
                     },
                     unquote(timeout)
    end
  end

  @doc """
  Refutes the channel has pushed a message back to the client on the given
  socket with the given event and payload within `timeout`.
  Works somilar to `Phoenix.ChannelTest.refute_push/2`.
  """
  defmacro refute_push_on(id, event, payload, timeout \\ 100) do
    quote do
      pid_or_id = unquote(__MODULE__).__get_pid_or_id__(unquote(id))

      refute_receive {
                       ^pid_or_id,
                       %Message{event: unquote(event), payload: unquote(payload)}
                     },
                     unquote(timeout)
    end
  end

  @doc """
  Asserts the channel has broadcasted a message back to the client on the given
  socket with the given event and payload within `timeout`.
  Works somilar to `Phoenix.ChannelTest.assert_broadcast/2`.
  """
  defmacro assert_broadcast_on(id, event, payload, timeout \\ 100) do
    quote do
      pid_or_id = unquote(__MODULE__).__get_pid_or_id__(unquote(id))

      assert_receive {
                       ^pid_or_id,
                       %Broadcast{event: unquote(event), payload: unquote(payload)}
                     },
                     unquote(timeout)
    end
  end

  @doc """
  Refutes the channel has broadcasted a message back to the client on the given
  socket with the given event and payload within `timeout`.
  Works somilar to `Phoenix.ChannelTest.refute_broadcast/2`.
  """
  defmacro refute_broadcast_on(id, event, payload, timeout \\ 100) do
    quote do
      pid_or_id = unquote(__MODULE__).__get_pid_or_id__(unquote(id))

      refute_receive {
                       ^pid_or_id,
                       %Broadcast{event: unquote(event), payload: unquote(payload)}
                     },
                     unquote(timeout)
    end
  end

  @doc false
  def __get_pid_or_id__(%Socket{transport_pid: pid}), do: pid
  def __get_pid_or_id__(any), do: any
end

defmodule SocketProxy.Proxy do
  @moduledoc """
  This GenServer acts as an proxy between the socket and the test process.
  It forwards all messages it receives along with an identifier for the proxy
  to the test process. That way assertions on the origin of a message can eaily
  be made.
  """

  use GenServer

  alias Phoenix.ChannelTest
  alias Phoenix.ChannelTest.NoopSerializer
  alias Phoenix.Socket
  alias Phoenix.Socket.Transport

  @typedoc """
  The internal state of the `Proxy`.

  * `pid` The `pid` of the process that invoked `start_link/1`.
  * `id` The identifier for the socket. Each message will be forwarded with
    the idenfifier.
  * `silent` Boolean to silence the socket. If `true` no messages will be
    forwarded.
  """
  @type state :: %{pid: pid, id: any, silent: boolean}

  @doc """
  Convinience function to call `start_link/2` with opts only.
  """
  @spec start_link(keyword) :: GenServer.on_start()
  def start_link([_ | _] = opts) do
    start_link(nil, opts)
  end

  @doc """
  Starts the `Proxy` and links it to the current process.

  When the argument is `nil` the `pid` of the `Proxy` is used as the
  identifier for the `Proxy`. Otherwise the first argument is used.

  Every time the `Proxy` receives a message, it wraps the message with the
  indentifier in a tuple and forwards it to the test process. That way
  assertions on the origin of a message can easily be made.
  """
  @spec start_link(any, keyword) :: GenServer.on_start()
  def start_link(id \\ nil, opts \\ []) do
    silent = Keyword.get(opts, :silent, false)
    GenServer.start_link(__MODULE__, %{pid: self(), id: id, silent: silent})
  end

  @doc false
  def init(%{id: nil} = state) do
    {:ok, %{state | id: self()}}
  end

  def init(state) do
    {:ok, state}
  end

  @doc """
  Connects the `Proxy` to a socket.

  Works similar to `Phoenix.ChannelTest.connect/2)` and will return the
  result of the `handler`'s `connect/2` callback.

  ## Arguments

  * `pid` The `pid` of the `Proxy`.
  * `endpoint` The module of the endpoint.
  * `handler` The module of the handler. Usually the `UserSocket`.
  * `params` The parameters that will be passed to the handlers `connect/2`
    callback.
  """
  @spec connect(pid, module, module, map) :: {:ok, Socket.t()} | :error
  def connect(pid, endpoint, handler, params) do
    GenServer.call(pid, {:connect, endpoint, handler, params})
  end

  @doc """
  Subscribes the `Proxy` to a channel.

  Utilizes `Phoenix.ChannelTest.subscribe_and_join/n)` to subscribe and join.

  ## Arguments

  * `pid` The `pid` of the `Proxy`.
  * `subscibe_and_join_args` A list of arguments for
    `Phoenix.ChannelTest.subscribe_and_join/n`. Usually something like
    `[socket, channel_module, topic, params]`.
  """
  @spec subscribe_and_join(pid, list(any)) ::
          {:ok, map, Socket.t()} | {:error, any}
  def subscribe_and_join(pid, subscribe_and_join_args) do
    GenServer.call(pid, {:subscribe_and_join, subscribe_and_join_args})
  end

  @doc """
  Returns the internal state of the `Proxy`.
  """
  @spec __state__(pid) :: state()
  def __state__(pid) do
    GenServer.call(pid, :state)
  end

  # Invoked when the socket sends any message to the proxy.
  def handle_info(_msg, %{silent: true} = state) do
    {:noreply, state}
  end

  def handle_info(msg, %{pid: pid, id: id} = state) do
    send(pid, {id, msg})
    {:noreply, state}
  end

  # `connect/4`
  #
  # Connects the proxy to the socket. The code is basically taken from
  # `Phoenix.ChannelTest.connect/2`.
  def handle_call({:connect, endpoint, handler, params}, _from, state) do
    result =
      endpoint
      |> do_connect(handler, params)
      |> do_subscribe()

    {:reply, result, state}
  end

  # `subscribe_and_join/2`
  #
  # Joins and subscribes the proxy to a channel.
  def handle_call(
        {:subscribe_and_join, sub_and_join_args},
        _from,
        state
      ) do
    result = apply(ChannelTest, :subscribe_and_join, sub_and_join_args)
    {:reply, result, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  defp do_connect(endpoint, handler, params) do
    Transport.connect(
      endpoint,
      handler,
      :channel_test,
      self(),
      NoopSerializer,
      ChannelTest.__stringify__(params)
    )
  end

  defp do_subscribe({:ok, socket}) do
    if topic = socket.handler.id(socket) do
      :ok = socket.endpoint.subscribe(topic)
    end

    {:ok, socket}
  end
end

defmodule SocketProxy do
  @moduledoc """
  Documentation for SocketProxy.
  """

  alias SocketProxy.Proxy
  alias Phoenix.Socket.Message
  alias Phoenix.Socket.Broadcast

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

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

  defmacro assert_push_on(id, event, payload, timeout \\ 100) do
    quote do
      assert_receive {
        unquote(id),
        %Message{event: unquote(event), payload: unquote(payload)}
      }, unquote(timeout)
    end
  end

  defmacro assert_broadcast_on(id, event, payload, timeout \\ 100) do
    quote do
      assert_receive {
        unquote(id),
        %Broadcast{event: unquote(event), payload: unquote(payload)}
      }, unquote(timeout)
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

  def start_proxy(id \\ nil) do
    Proxy.start_link(id)
  end

  def subscribe_and_join_proxy(socket, channel, topic, params \\ %{}) do
    Proxy.subscribe_and_join(socket.transport_pid, [
      socket,
      channel,
      topic,
      params
    ])
  end

  def subscribe_and_join_proxy!(socket, channel, topic, params \\ %{}) do
    case subscribe_and_join_proxy(socket, channel, topic, params) do
      {:ok, _, socket} ->
        socket
      {:error, error} ->
        raise "could not join channel, got error: #{inspect(error)}"
    end
  end
end

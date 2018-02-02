defmodule SocketProxy.Proxy do
  @moduledoc """
  This GenServer acts as an proxy between the socket and the test process.
  It forwars all `Phoenix.Socket.Message` and `Phoenix.Socket.Broadcast`
  messages it receives to a stored process along with a stored id.
  """

  use GenServer

  alias Phoenix.ChannelTest
  alias Phoenix.ChannelTest.NoopSerializer
  alias Phoenix.Socket.Transport
  alias Phoenix.Socket.Message
  alias Phoenix.Socket.Broadcast

  def start_link(opts \\ []) do
    pid = Keyword.get(opts, :pid, self())
    id = Keyword.fetch!(opts, :id)
    GenServer.start_link(__MODULE__, %{pid: pid, id: id})
  end

  def init(opts) do
    {:ok, opts}
  end

  def connect(pid, endpoint, handler, params) do
    GenServer.call(pid, {:connect, endpoint, handler, params})
  end

  def __state__(pid) do
    GenServer.call(pid, :state)
  end

  def handle_info(%Message{} = msg, %{pid: pid, id: id} = state) do
    send(pid, {id, msg})
    {:noreply, state}
  end

  def handle_info(%Broadcast{} = msg, %{pid: pid, id: id} = state) do
    send(pid, {id, msg})
    {:noreply, state}
  end

  def handle_call({:connect, endpoint, handler, params}, _from, state) do
    result =
      endpoint
      |> do_connect(handler, params)
      |> do_subscribe()

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

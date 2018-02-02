defmodule SocketProxy.Proxy do
  use GenServer

  alias Phoenix.ChannelTest
  alias Phoenix.ChannelTest.NoopSerializer
  alias Phoenix.Socket
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

  def subscribe_and_join!(
    %Socket{transport_pid: pid} = socket,
    channel_mod,
    topic,
    params
  ) do
    GenServer.call(
      pid,
      {:subscribe_and_join!, socket, channel_mod, topic, params}
    )
  end

  @doc false
  def __state__(pid) do
    GenServer.call(pid, :state)
  end

  def handle_info(%Message{} = push, %{pid: pid, id: id} = state) do
    IO.puts """
    ================== PUSH ==================
    #{inspect push}
    """
    send(pid, {id, :push, push})
    {:noreply, state}
  end

  def handle_info(%Broadcast{} = broadcast, %{pid: pid, id: id} = state) do
    IO.puts """
    ================== BROADCAST ==================
    #{inspect broadcast}
    """
    send(pid, {id, :broadcast, broadcast})
    {:noreply, state}
  end

  def handle_call({:connect, endpoint, handler, params}, _from, state) do
    tuple =
      endpoint
      |> do_connect(handler, params)
      |> do_subscribe()

    {:reply, tuple, state}
  end

  def handle_call(
    {:subscribe_and_join!, socket, channel_mod, topic, params},
    _from,
    state
  ) do
    tuple = ChannelTest.subscribe_and_join(
      socket,
      channel_mod,
      topic,
      params
    )

    {:reply, tuple, state}
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

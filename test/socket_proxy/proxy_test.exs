defmodule SocketProxy.ProxyTest do
  use ExUnit.Case, async: true

  alias Phoenix.Socket
  alias Phoenix.Socket.Message
  alias Phoenix.Socket.Broadcast
  alias SocketProxy.Proxy
  alias SocketProxyWeb.Endpoint
  alias SocketProxyWeb.UserSocket

  describe "start_link/1" do
    test "starts a proxy" do
      assert {:ok, pid} = Proxy.start_link(id: :test)
    end

    test "raises an error without an id" do
      assert_raise KeyError, fn ->
        Proxy.start_link()
      end
    end

    test "sets up the state" do
      {:ok, pid} = Proxy.start_link(id: :test)
      expected_pid = self()
      assert %{pid: ^expected_pid, id: :test} = Proxy.__state__(pid)
    end
  end

  describe "connect/4" do
    setup do
      id = System.unique_integer()
      {:ok, pid} = Proxy.start_link(id: id)
      {:ok, pid: pid, id: id}
    end

    test "builds a socket", %{pid: pid, id: id} do
      assert {:ok, socket} =
        Proxy.connect(pid, Endpoint, UserSocket, %{"name" => "alice"})
      assert %Socket{} = socket
      assert socket.transport_pid
      refute socket.transport_pid == self()
      assert socket.endpoint == Endpoint
      assert socket.handler == UserSocket
    end
  end

  describe "acting as a message proxy for broadcasts and messages" do
    setup do
      id = System.unique_integer()
      {:ok, pid} = Proxy.start_link(id: id)
      {:ok, pid: pid, id: id}
    end

    test """
    When the proxy receives a broadcast it wraps the message in a tuple
    with the stored id and forwards it to the stored process.
    """, %{id: id, pid: pid} do
      msg = %Broadcast{event: System.unique_integer()}
      send(pid, msg)
      assert_receive {^id, ^msg}
    end

    test """
    When the proxy receives a message it wraps the message in a tuple
    with the stored id and forwards it to the stored process.
    """, %{id: id, pid: pid} do
      msg = %Message{ref: System.unique_integer()}
      send(pid, msg)
      assert_receive {^id, ^msg}
    end
  end
end

defmodule SocketProxy.ProxyTest do
  use ExUnit.Case, async: true

  alias Phoenix.Socket
  alias Phoenix.Socket.Message
  alias Phoenix.Socket.Broadcast
  alias SocketProxy.Proxy
  alias SocketProxyWeb.Endpoint
  alias SocketProxyWeb.UserSocket
  alias SocketProxyWeb.RoomChannel

  describe "start_link/1" do
    test "starts a proxy with given id" do
      assert {:ok, pid} = Proxy.start_link(:test)
      assert is_pid(pid)
      expected_pid = self()
      assert %{pid: ^expected_pid, id: :test} = Proxy.__state__(pid)
    end

    test "starts a proxy with nil" do
      assert {:ok, pid} = Proxy.start_link(nil)
      assert is_pid(pid)
      expected_pid = self()
      assert %{pid: ^expected_pid, id: ^pid} = Proxy.__state__(pid)
    end

    test "starts a proxy without arg" do
      assert {:ok, pid} = Proxy.start_link()
      assert is_pid(pid)
      expected_pid = self()
      assert %{pid: ^expected_pid, id: ^pid} = Proxy.__state__(pid)
    end
  end

  describe "start_link/0" do
    test "starts a proxy" do
      assert {:ok, pid} = Proxy.start_link()
      assert is_pid(pid)
    end

    test "sets up the expected state" do
      {:ok, pid} = Proxy.start_link()
      expected_pid = self()
      assert %{pid: ^expected_pid, id: ^pid} = Proxy.__state__(pid)
    end
  end

  describe "connect/4" do
    setup do
      {:ok, pid} = Proxy.start_link()
      {:ok, pid: pid}
    end

    test "builds a socket", %{pid: pid} do
      assert {:ok, socket} =
        Proxy.connect(pid, Endpoint, UserSocket, %{"name" => "alice"})
      assert %Socket{} = socket
      assert socket.transport_pid
      refute socket.transport_pid == self()
      assert socket.endpoint == Endpoint
      assert socket.handler == UserSocket
    end
  end

  describe "subscribe_and_join/2" do
    test "subscribes to a channel" do
      {:ok, pid} = Proxy.start_link()
      {:ok, socket} = Proxy.connect(
        pid,
        Endpoint,
        UserSocket,
        %{"name" => "alice"}
      )
      {:ok, _, %Socket{}} =
        Proxy.subscribe_and_join(pid, [socket, RoomChannel, "room:1"])
      assert_receive {^pid, _}
    end
  end

  describe "acting as a message proxy for broadcasts and messages" do
    setup do
      {:ok, pid} = Proxy.start_link()
      {:ok, pid: pid}
    end

    test """
    When the proxy receives a broadcast it wraps the message in a tuple
    with the stored id and forwards it to the stored process.
    """, %{pid: pid} do
      msg = %Broadcast{event: System.unique_integer()}
      send(pid, msg)
      assert_receive {^pid, ^msg}
    end

    test """
    When the proxy receives a message it wraps the message in a tuple
    with the stored id and forwards it to the stored process.
    """, %{pid: pid} do
      msg = %Message{ref: System.unique_integer()}
      send(pid, msg)
      assert_receive {^pid, ^msg}
    end
  end
end

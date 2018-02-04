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
      assert_push_on(socket, "msg", %{"body" => "Welcome alice!"})
      refute_push_on(socket, "msg", %{"body" => "Get out of here!"})
      refute_broadcast_on(socket, "shout", %{"body" => "Hello World!"})
    end

    test "assertions on the proxy's pid", %{proxy_pid: pid} do
      assert_push_on(pid, "msg", %{"body" => "Welcome alice!"})
    end

    test "good old assert_receive", %{proxy_pid: pid} do
      assert_receive {^pid,
                      %Phoenix.Socket.Message{
                        payload: %{"body" => "Welcome alice!"}
                      }}
    end

    test "pushing messages", %{proxy_socket: socket} do
      push(socket, "shout", %{"body" => "Hello World!"})
      assert_broadcast_on(socket, "shout", %{"body" => "Hello World!"})
    end
  end

  describe "using custom identifiers" do
    setup do
      {:ok, proxy_pid} = start_proxy(:alice_socket)
      params = %{"name" => "alice"}
      {:ok, socket} = connect_proxy(proxy_pid, UserSocket, params)
      subscribe_and_join_proxy!(socket, RoomChannel, "room:1")

      :ok
    end

    test "assertions on the custom identifier" do
      assert_push_on(:alice_socket, "msg", %{"body" => "Welcome alice!"})
      refute_push_on(:alice_socket, "msg", %{"body" => "Get out of here!"})
    end
  end
end

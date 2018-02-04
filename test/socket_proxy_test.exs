defmodule SocketProxyTest do
  use SocketProxyWeb.ChannelCase
  use SocketProxy

  alias SocketProxy.Proxy
  alias SocketProxyWeb.UserSocket

  describe "start_proxy/1" do
    test "sets an id when no arg given" do
      assert {:ok, pid} = start_proxy()
      %{id: ^pid} = Proxy.__state__(pid)
    end

    test "sets the argument as id" do
      assert {:ok, pid} = start_proxy(:test_id)
      %{id: :test_id} = Proxy.__state__(pid)
    end
  end

  describe "connect_proxy/2" do
    test "connect to a socket" do
      {:ok, pid} = start_proxy(:test_id)
      assert {:ok, _} = connect_proxy(pid, UserSocket, %{"name" => "alice"})
    end
  end
end

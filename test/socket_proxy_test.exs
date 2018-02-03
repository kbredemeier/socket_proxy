defmodule SocketProxyTest do
  use ExUnit.Case
  use SocketProxy,
    endpoint: SocketProxyWeb.Endpoint,
  use Phoenix.ChannelTest

  alias SocketProxy.Proxy
  alias SocketProxyWeb.UserSocket

  @endpoint SocketProxyWeb.Endpoint

  describe "start_proxy/1" do
    test "generates an id" do
      assert {:ok, pid} = start_proxy()
      %{id: id} = Proxy.__state__(pid)
      assert is_integer(id)
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

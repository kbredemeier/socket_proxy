defmodule SocketProxy.IntegrationTest do
  use ExUnit.Case
  use SocketProxy,
    endpoint: SocketProxyWeb.Endpoint
  use Phoenix.ChannelTest

  import Phoenix.ChannelTest

  alias Phoenix.Socket.Broadcast
  alias Phoenix.Socket.Message
  alias SocketProxyWeb.RoomChannel
  alias SocketProxyWeb.UserSocket

  @endpoint SocketProxyWeb.Endpoint

  defp join_room({:ok, socket}, id) do
    subscribe_and_join_proxy!(socket, RoomChannel, "room:#{id}")
  end

  describe "The test receives messages with id of the proxy" do
    setup do
      {:ok, alice_proxy} = start_proxy()
      {:ok, bob_proxy} = start_proxy()

      alice_socket =
        alice_proxy
        |> connect_proxy(UserSocket, %{"name" => "alice"})
        |> join_room(1)

      bob_socket =
        bob_proxy
        |> connect_proxy(UserSocket, %{"name" => "bob"})
        |> join_room(1)

      {:ok,
        alice_proxy: alice_proxy,
        alice_socket: alice_socket,
        bob_proxy: bob_proxy,
        bob_socket: bob_socket
      }
    end

    test "it works for Phoenix.Socket.Message",
    %{alice_proxy: alice_proxy, bob_proxy: bob_proxy} do
      assert_receive {^alice_proxy, %Message{
        payload: %{"body" => "Welcome alice!"}
      }}

      refute_receive {^alice_proxy, %Message{
        payload: %{"body" => "Welcome bob"}
      }}

      assert_receive {^alice_proxy, %Message{
        payload: %{"body" => "bob joined the room."}
      }}

      assert_receive {^bob_proxy, %Message{
        payload: %{"body" => "Welcome bob!"}
      }}

      refute_receive {^bob_proxy, %Message{
        payload: %{"body" => "bob joined the room."}
      }}
    end

    test "it works for Phoenix.Socket.Broadcast", %{
      alice_socket: alice_socket, alice_proxy: alice_proxy, bob_proxy: bob_proxy
    } do
      push(alice_socket, "shout", %{"body" => "test"})

      assert_receive {^bob_proxy, %Broadcast{
        payload: %{"body" => "test"}
      }}

      assert_receive {^alice_proxy, %Broadcast{
        payload: %{"body" => "test"}
      }}
    end
  end
end

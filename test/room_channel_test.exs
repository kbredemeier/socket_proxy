defmodule SocketProxyWeb.RoomChannelTest do
  use ExUnit.Case
  use SocketProxy,
    endpoint: SocketProxyWeb.Endpoint
  use Phoenix.ChannelTest

  import Phoenix.ChannelTest

  alias Phoenix.Socket.Broadcast
  alias Phoenix.Socket.Message
  alias SocketProxy.Proxy
  alias SocketProxyWeb.RoomChannel
  alias SocketProxyWeb.UserSocket

  @endpoint SocketProxyWeb.Endpoint

  defp join_room({:ok, socket}, id) do
    subscribe_and_join!(socket, RoomChannel, "room:#{id}")
  end

  test "when alice enters the room she receives a welcome msg" do
    {:ok, pid} = start_proxy(:alice)
    socket =
      pid
      |> connect_proxy(UserSocket, %{"name" => "alice"})
      |> join_room(1)

    assert_receive {:alice, %Message{
      payload: %{"body" => "Welcome alice!"}
    }}
    refute_receive {:alice, _}
  end

  test """
  When Alice is already in the room and bob enters, Bob is anounced in the
  room and he receives a welcome msg
  """ do
    {:ok, alice_proxy} = start_proxy(:alice)
    {:ok, bob_proxy} = start_proxy(:alice)
    socket =
      pid
      |> connect_proxy(UserSocket, %{"name" => "alice"})
      |> join_room(1)

    socket =
      pid
      |> connect_proxy(UserSocket, %{"name" => "alice"})
      |> join_room(1)

    refute_receive {:alice, %Message{
      payload: %{"body" => "Welcome bob"}
    }}

    assert_receive {:alice, %Broadcast{
      payload: %{"body" => "bob joined the room."}
    }}

    assert_receive {:bob, %Message{
      payload: %{"body" => "Welcome bob"}
    }}

    refute_receive {:bob, %Broadcast{
      payload: %{"body" => "bob joined the room."}
    }}
  end
end

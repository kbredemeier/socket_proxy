defmodule SocketProxy.IntegrationTest do
  use SocketProxyWeb.ChannelCase
  use SocketProxy

  alias Phoenix.Socket.Broadcast
  alias Phoenix.Socket.Message
  alias SocketProxyWeb.RoomChannel
  alias SocketProxyWeb.UserSocket

  defp join_room({:ok, socket}, id) do
    subscribe_and_join_proxy!(socket, RoomChannel, "room:#{id}")
  end

  describe "assert_reply/5" do
    setup do
      {:ok, proxy} = start_proxy()

      socket =
        proxy
        |> connect_proxy(UserSocket, %{"name" => "alice"})
        |> join_room(1)

      ref = push(socket, "reply", %{"body" => "test"})

      {:ok, proxy: proxy, socket: socket, ref: ref}
    end

    test "it works with the proxy pid", %{proxy: proxy, ref: ref} do
      assert_reply_on proxy, ref, :ok
    end

    test "it works with the proxy socket", %{socket: socket, ref: ref} do
      assert_reply_on socket, ref, :ok
    end

    test "it fails when the message is not received", %{socket: socket, ref: ref} do
      assert_raise ExUnit.AssertionError, fn ->
        assert_reply_on socket, ref, :error
      end
    end
  end

  describe "refute_reply/5" do
    setup do
      {:ok, proxy} = start_proxy()

      socket =
        proxy
        |> connect_proxy(UserSocket, %{"name" => "alice"})
        |> join_room(1)

      ref = push(socket, "reply", %{"body" => "test"})

      {:ok, proxy: proxy, socket: socket, ref: ref}
    end

    test "it works with the proxy pid", %{proxy: proxy, ref: ref} do
      refute_reply_on proxy, ref, :error
    end

    test "it works with the proxy socket", %{socket: socket, ref: ref} do
      refute_reply_on socket, ref, :error
    end

    test "it fails when the message is not received", %{socket: socket, ref: ref} do
      assert_raise ExUnit.AssertionError, fn ->
        refute_reply_on socket, ref, :ok
      end
    end
  end

  describe "assert_push_on/4" do
    setup do
      {:ok, proxy} = start_proxy()

      socket =
        proxy
        |> connect_proxy(UserSocket, %{"name" => "alice"})
        |> join_room(1)

      {:ok, proxy: proxy, socket: socket}
    end

    test "it works with the proxy pid", %{proxy: proxy} do
      assert_push_on(proxy, "msg", %{"body" => "Welcome alice!"})
    end

    test "it works with the proxy socket", %{socket: socket} do
      assert_push_on(socket, "msg", %{"body" => "Welcome alice!"})
    end

    test "it fails when the message is not received" do
      id = :wrong_id

      assert_raise ExUnit.AssertionError, fn ->
        assert_push_on(id, "msg", %{"body" => "Welcome alice!"})
      end
    end
  end

  describe "refute_push_on/4" do
    setup do
      {:ok, proxy} = start_proxy()

      socket =
        proxy
        |> connect_proxy(UserSocket, %{"name" => "alice"})
        |> join_room(1)

      {:ok, proxy: proxy, socket: socket}
    end

    test "it works with the proxy pid", %{proxy: proxy} do
      refute_push_on(proxy, "msg", %{"foo" => "bar"})
    end

    test "it works with the proxy socket", %{socket: socket} do
      refute_push_on(socket, "msg", %{"foo" => "bar"})
    end

    test "it fails when the message is received", %{socket: socket} do
      assert_raise ExUnit.AssertionError, fn ->
        refute_push_on(socket, "msg", %{"body" => "Welcome alice!"})
      end
    end
  end

  describe "assert_broadcast_on/4" do
    setup do
      {:ok, proxy} = start_proxy()

      socket =
        proxy
        |> connect_proxy(UserSocket, %{"name" => "alice"})
        |> join_room(1)

      push(socket, "shout", %{"body" => "test"})

      {:ok, proxy: proxy, socket: socket}
    end

    test "it works with the proxy pid", %{proxy: proxy} do
      assert_broadcast_on(proxy, "shout", %{"body" => "test"})
    end

    test "it works with the proxy socket", %{socket: socket} do
      assert_broadcast_on(socket, "shout", %{"body" => "test"})
    end

    test "it fails when the message is not received" do
      id = :wrong_id

      assert_raise ExUnit.AssertionError, fn ->
        assert_broadcast_on(id, "shout", %{"body" => "test"})
      end
    end
  end

  describe "refute_broadcast_on/4" do
    setup do
      {:ok, proxy} = start_proxy()

      socket =
        proxy
        |> connect_proxy(UserSocket, %{"name" => "alice"})
        |> join_room(1)

      push(socket, "shout", %{"body" => "test"})

      {:ok, proxy: proxy, socket: socket}
    end

    test "it works with the proxy pid", %{proxy: proxy} do
      refute_broadcast_on(proxy, "shout", %{"body" => "false"})
    end

    test "it works with the proxy socket", %{socket: socket} do
      refute_broadcast_on(socket, "shout", %{"body" => "false"})
    end

    test "it fails when the unexpected message is received", %{socket: socket} do
      assert_raise ExUnit.AssertionError, fn ->
        refute_broadcast_on(socket, "shout", %{"body" => "test"})
      end
    end
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
       bob_socket: bob_socket}
    end

    test "it works for Phoenix.Socket.Message", %{alice_proxy: alice_proxy, bob_proxy: bob_proxy} do
      assert_receive {^alice_proxy,
                      %Message{
                        payload: %{"body" => "Welcome alice!"}
                      }}

      refute_receive {^alice_proxy,
                      %Message{
                        payload: %{"body" => "Welcome bob"}
                      }}

      assert_receive {^alice_proxy,
                      %Message{
                        payload: %{"body" => "bob joined the room."}
                      }}

      assert_receive {^bob_proxy,
                      %Message{
                        payload: %{"body" => "Welcome bob!"}
                      }}

      refute_receive {^bob_proxy,
                      %Message{
                        payload: %{"body" => "bob joined the room."}
                      }}
    end

    test "it works for Phoenix.Socket.Broadcast", %{
      alice_socket: alice_socket,
      alice_proxy: alice_proxy,
      bob_proxy: bob_proxy
    } do
      push(alice_socket, "shout", %{"body" => "test"})

      assert_receive {^bob_proxy,
                      %Broadcast{
                        payload: %{"body" => "test"}
                      }}

      assert_receive {^alice_proxy,
                      %Broadcast{
                        payload: %{"body" => "test"}
                      }}
    end
  end
end

# SocketProxy
[![Build Status](https://travis-ci.org/kbredemeier/socket_proxy.svg?branch=master)](https://travis-ci.org/kbredemeier/socket_proxy)

*WARNING* This library is currently in alpha stage and might change in the near
future.

Convinience for testing multiple socket connections.

When testing a `Phoenix.Channel` you might run into one of the following
situations:

* You want to make sure that a message is received on a specific user's socket
* You want to terminate the transport process.
* You want to isolate the messages you receive in your test.

If you ever found yourself in one of these situations this library might come
in handy.

When using the functions provided by `Phoenix.ChannelTest` to connect to a
socket or join a channel the socket or channel will be linked to the pid of
the test. The test process will receive all the `Phoenix.Socket.Message` and
`Phoenix.Socket.Broadcast` that would otherwise pushed to the client.

Unfortunately this way it is impossible to assert that a message was sent
on a specific socket, nor is it possible to to realy close the socket because
the `transport_pid` of the socket is the test itself.

This is where `SocketProxy` comes in. It proxies the socket connection through
a seperate process and tags the messages so that its origin can be asserted
on.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `socket_proxy` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:socket_proxy, "~> 0.1.0", only: :test},
  ]
end
```

## Example

```elixir
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
      assert_push_on socket, "msg", %{"body" => "Welcome alice!"}
      refute_push_on socket, "msg", %{"body" => "Get out of here!"}
      refute_broadcast_on socket, "shout", %{"body" => "Hello World!"}
    end

    test "assertions on the proxy's pid", %{proxy_pid: pid} do
      assert_push_on pid, "msg", %{"body" => "Welcome alice!"}
    end

    test "good old assert_receive", %{proxy_pid: pid} do
      assert_receive {^pid, %Phoenix.Socket.Message{
        payload: %{"body" => "Welcome alice!"}
      }}
    end

    test "pushing messages", %{proxy_socket: socket} do
      push(socket, "shout", %{"body" => "Hello World!"})
      assert_broadcast_on socket, "shout", %{"body" => "Hello World!"}
    end
  end

  describe "using custom identifiers" do
    setup do
      {:ok, proxy_pid} = start_proxy(:alice_socket)
      params = %{"name" => "alice"}
      {:ok, socket} = connect_proxy(proxy_pid, UserSocket, params)
      socket = subscribe_and_join_proxy!(socket, RoomChannel, "room:1")

      :ok
    end

    test "assertions on the custom identifier" do
      assert_push_on :alice_socket, "msg", %{"body" => "Welcome alice!"}
      refute_push_on :alice_socket, "msg", %{"body" => "Get out of here!"}
    end
  end
end
```

## TODO

* Add examples for `assert_reply` and `refute_reply`
* Add examples for silent option
* Test if `leave/1` and `close/1` works as expected


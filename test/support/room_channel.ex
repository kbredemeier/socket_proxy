defmodule SocketProxyWeb.RoomChannel do
  use SocketProxyWeb, :channel

  alias SocketProxyWeb.UserSocket

  def join("room:" <> room_id, payload, socket) do
    {:ok, assign(socket, :room_id, room_id)}
  end
end

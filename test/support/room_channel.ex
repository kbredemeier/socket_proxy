  defmodule SocketProxyWeb.RoomChannel do
    use SocketProxyWeb, :channel

    def join("room:" <> room_id, payload, socket) do
      send(self(), :announce_user)
      {:ok, assign(socket, :room_id, room_id)}
    end

  def handle_info(:announce_user, socket) do
    user_name = socket.assigns.user.name

    broadcast_msg = "#{user_name} joined the room."
    broadcast_from(socket, "msg", %{msg: broadcast_msg})

    push_msg = "Welcome #{user_name}!"
    push(socket, "msg", %{"body" => push_msg})

    {:noreply, socket}
  end
end

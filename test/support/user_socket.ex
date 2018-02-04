defmodule SocketProxyWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel("room:*", SocketProxyWeb.RoomChannel)

  ## Transports
  transport(:websocket, Phoenix.Transports.WebSocket)

  def connect(params, socket) do
    case authorized(params) do
      {:ok, user} -> {:ok, assign(socket, :user, user)}
      _error -> :error
    end
  end

  def id(socket), do: "user_socket:#{socket.assigns.user.id}"

  defp authorized(%{"name" => "alice"}) do
    {:ok, %{name: "alice", id: "1"}}
  end

  defp authorized(%{"name" => "bob"}) do
    {:ok, %{name: "bob", id: "2"}}
  end

  defp authorized(_), do: :error
end

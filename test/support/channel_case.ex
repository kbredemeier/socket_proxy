defmodule SocketProxyWeb.ChannelCase do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case
      use Phoenix.ChannelTest
      import Phoenix.ChannelTest

      @endpoint SocketProxyWeb.Endpoint
    end
  end
end

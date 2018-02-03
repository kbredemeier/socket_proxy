defmodule SocketProxy do
  @moduledoc """
  Documentation for SocketProxy.
  """

  alias SocketProxy.Proxy

  defmacro __using__(opts \\ []) do
    endpoint = Keyword.fetch!(opts, :endpoint)

    quote location: :keep do
      import unquote(__MODULE__)
      alias SocketProxy.Proxy

      def connect_proxy(pid, handler, params \\ %{}) do
        Proxy.connect(
          pid,
          unquote(endpoint),
          handler,
          params
        )
      end
    end
  end

  def start_proxy(id \\ nil) do
    id = id || System.unique_integer()
    Proxy.start_link(id: id)
  end
end

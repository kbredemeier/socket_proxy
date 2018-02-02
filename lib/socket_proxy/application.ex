defmodule SocketProxy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    do_start(Mix.env)
  end

  defp do_start(:test) do
    import Supervisor.Spec
    # List all child processes to be supervised
    children = [
      supervisor(SocketProxyWeb.Endpoint, []),
    ]

    opts = [strategy: :one_for_one, name: SocketProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp do_start(_), do: :ok
end

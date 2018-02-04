defmodule SocketProxy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    # List all child processes to be supervised
    children = [
      supervisor(SocketProxyWeb.Endpoint, []),
    ]

    opts = [strategy: :one_for_one, name: SocketProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

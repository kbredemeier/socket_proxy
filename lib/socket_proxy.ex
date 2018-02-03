defmodule SocketProxy do
  @moduledoc """
  Documentation for SocketProxy.
  """

  alias SocketProxy.Proxy

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro connect_proxy(pid, handler, params \\ %{}) do
    if endpoint = Module.get_attribute(__CALLER__.module, :endpoint) do
      quote do
        unquote(__MODULE__).__connect_proxy__(
          unquote(pid),
          unquote(endpoint),
          unquote(handler),
          unquote(params)
        )
      end
    else
      raise "module attribute @endpoint not set for socket/2"
    end
  end

  @doc false
  def __connect_proxy__(proxy_pid, endpoint, handler, params) do
    Proxy.connect(
      proxy_pid,
      endpoint,
      handler,
      params
    )
  end

  def start_proxy(id \\ nil) do
    id = id || System.unique_integer()
    Proxy.start_link(id: id)
  end
end

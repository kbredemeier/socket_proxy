defmodule SocketProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :socket_proxy,
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "SocketPoxy",
      source_url: "https://github.com/kbredemeier/socket_proxy",
      # The main page in the docs
      docs: [main: "SocketProxy", extras: ["README.md"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    build_application(Mix.env())
  end

  defp build_application(:test) do
    build_application(nil) ++ [mod: {SocketProxy.Application, []}]
  end

  defp build_application(_) do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"}
    ]
  end
end

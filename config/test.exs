use Mix.Config

config :socket_proxy, SocketProxyWeb.Endpoint,
  url: [host: "localhost"],
  http: [port: 4001],
  secret_key_base: "P72f47f63E3xBUAO1wAb0iFmGAwE1+M1y/l9ucve25OCcQPtc4PA62Fw1bFjWJ9d",
  server: false,
  pubsub: [name: SocketProxy.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  level: :warn,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

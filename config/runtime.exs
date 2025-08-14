import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in this file, as it won't be applied.

# Configure endpoint for all environments
host = System.get_env("PHX_HOST") || "localhost"
port = String.to_integer(System.get_env("PORT") || "9999")

config :pit, PitWeb.Endpoint,
  url: [host: host, port: port, scheme: "http"],
  http: [
    # Enable IPv6 and bind on all interfaces.
    # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
    # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options.html/0
    ip: {0, 0, 0, 0, 0, 0, 0, 0},
    port: port
  ]

# Configure secret key base for production
if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      "CqoOekXLG7Xzj41wF7a+Z5b7FRYc4F94l3dfmIHBhnbwVbnL9rMZ5QiETyCNUT9t"

  config :pit, PitWeb.Endpoint,
    secret_key_base: secret_key_base
end

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :pit, PitWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SSL_KEYFILE"),
  #         certfile: System.get_env("SSL_CERTFILE")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # `priv/ssl/server.key`. For all supported SSL configuration
  # options, see https://hexdocs.pm/bandit/Bandit.html#t:options.html/0
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :pit, PitWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.



# Configure database
if System.get_env("DB_CONN_URL") do
  config :pit, Pit.Repo,
    url: System.get_env("DB_CONN_URL"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5"),
    queue_target: 5000,
    queue_interval: 10_000,
    timeout: 15_000,
    pool_timeout: 5000
else
  config :pit, Pit.Repo,
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "pit_dev",
    pool_size: 5,
    queue_target: 5000,
    queue_interval: 10_000,
    timeout: 15_000,
    pool_timeout: 5000
end

# Configure payment processor URLs
config :pit, :payment_processors,
  default_url: System.get_env("PAYMENT_SERVICE_URL_DEFAULT") || "http://payment-processor-default:8080",
  fallback_url: System.get_env("PAYMENT_SERVICE_URL_FALLBACK") || "http://payment-processor-fallback:8080"

# Configure logging level for production
config :logger, level: :info

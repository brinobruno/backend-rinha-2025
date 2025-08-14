import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :pit, PitWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "CqoOekXLG7Xzj41wF7a+Z5b7FRYc4F94l3dfmIHBhnbwVbnL9rMZ5QiETyCNUT9t",
  watchers: []

# Enable dev routes for dashboard and mailbox
config :pit, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Configure your database
config :pit, Pit.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "pit_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 5,
  queue_target: 5000,
  queue_interval: 10_000,
  timeout: 15_000,
  pool_timeout: 5000

# Configure secret key base for development
config :pit, PitWeb.Endpoint,
  secret_key_base: "CqoOekXLG7Xzj41wF7a+Z5b7FRYc4F94l3dfmIHBhnbwVbnL9rMZ5QiETyCNUT9t"

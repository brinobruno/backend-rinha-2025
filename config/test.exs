import Config

# Configure your database
config :pit, Pit.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "pit_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# Configure secret key base for test
config :pit, PitWeb.Endpoint,
  secret_key_base: "CqoOekXLG7Xzj41wF7a+Z5b7FRYc4F94l3dfmIHBhnbwVbnL9rMZ5QiETyCNUT9t"

# Configure payment processor URLs for test
config :pit, :payment_processors,
  default_url: "http://localhost:8001",
  fallback_url: "http://localhost:8002"

# We don't run a server during test. If you need to do so, you can
# enable the server option below.
config :pit, PitWeb.Endpoint, server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :pit, PitWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "z0Cw8E4fI0m+CW29d/g/Ks35XZhe6XNcJBYyqq1E6fMBES1/aLkzsYcFaRHXYcmO",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

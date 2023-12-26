import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :true_anomaly, TrueAnomaly.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "true_anomaly_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :true_anomaly, TrueAnomalyWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "XrAhdGJp8B6fMX3b/vLGnWQHoFSG5QBO8K+ssNsG5P3dUeVaAtGgvr7gEJLK+bAs",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

import Config

config :contexted, ecto_repos: [Contexted.TestApp.Repo]

config :contexted, Contexted.TestApp.Repo,
  database: "contexted_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: false

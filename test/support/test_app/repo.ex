defmodule Contexted.TestApp.Repo do
  use Ecto.Repo,
    otp_app: :contexted,
    adapter: Ecto.Adapters.Postgres
end

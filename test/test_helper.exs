ExUnit.start()

{:ok, _} = Ecto.Adapters.Postgres.ensure_all_started(Contexted.TestApp.Repo, :temporary)
{:ok, _pid} = Contexted.TestApp.Repo.start_link()

Process.flag(:trap_exit, true)

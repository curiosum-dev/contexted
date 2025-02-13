defmodule Contexted.DataCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias Contexted.TestApp.Repo
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias Contexted.TestApp.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Contexted.DataCase
      import Contexted.TestRecords, only: [test_records: 1]
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Repo)

    unless tags[:async] do
      Sandbox.mode(Repo, {:shared, self()})
    end

    :ok
  end
end

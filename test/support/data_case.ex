defmodule Contexted.DataCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias Contexted.TestApp.Repo
  alias Ecto.Adapters.SQL.Sandbox

  setup tags do
    :ok = Sandbox.checkout(Repo)

    unless tags[:async] do
      Sandbox.mode(Repo, {:shared, self()})
    end

    :ok
  end
end

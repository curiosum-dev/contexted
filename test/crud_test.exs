defmodule Contexted.CRUDTest do
  use ExUnit.Case

  defmodule TestApp do
    defmodule User do
      defstruct [:id]
      def changeset(struct, _attrs), do: struct
    end

    defmodule Repo do
      def all(_queryable), do: [:from_write_repo]
      def get(_queryable, _id), do: :from_write_repo
      def get!(_queryable, _id), do: :from_write_repo
      def insert(record), do: {:ok, {:write, record}}
      def insert!(record), do: {:write, record}
      def update(record), do: {:ok, {:write, record}}
      def update!(record), do: {:write, record}
      def delete(record), do: {:ok, {:write, record}}
      def delete!(record), do: {:write, record}
      def in_transaction?, do: Process.get(:in_tx?) == true
      def replica, do: Contexted.CRUDTest.TestApp.ReadRepo

      def transact(fun) when is_function(fun, 0) do
        Process.put(:in_tx?, true)

        try do
          fun.()
        after
          Process.delete(:in_tx?)
        end
      end
    end

    defmodule ReadRepo do
      def all(_queryable), do: [:from_read_repo]
      def get(_queryable, _id), do: :from_read_repo
      def get!(_queryable, _id), do: :from_read_repo
    end

    defmodule Users do
      use Contexted.CRUD,
        repo: Repo,
        schema: User,
        read_repo: {Repo, :replica}
    end

    defmodule UsersWithoutReplica do
      use Contexted.CRUD,
        repo: Repo,
        schema: User
    end
  end

  test "read_repo MFA routes list/get to replica repo" do
    assert TestApp.Users.list_users() == [:from_read_repo]
    assert TestApp.Users.get_user(1) == :from_read_repo
    assert TestApp.Users.get_user!(1) == :from_read_repo
  end

  test "reads use primary repo inside transaction" do
    TestApp.Repo.transact(fn ->
      assert TestApp.Users.list_users() == [:from_write_repo]
      assert TestApp.Users.get_user(1) == :from_write_repo
      assert TestApp.Users.get_user!(1) == :from_write_repo
    end)
  end

  test "writes still use primary repo" do
    assert {:ok, {:write, %TestApp.User{}}} = TestApp.Users.create_user()
    assert {:write, %TestApp.User{}} = TestApp.Users.create_user!(%TestApp.User{id: 1})
    assert {:ok, {:write, %TestApp.User{}}} = TestApp.Users.update_user(%TestApp.User{})
    assert {:write, %TestApp.User{}} = TestApp.Users.update_user!(%TestApp.User{})
    assert {:ok, {:write, %TestApp.User{}}} = TestApp.Users.delete_user(%TestApp.User{})
    assert {:write, %TestApp.User{}} = TestApp.Users.delete_user!(%TestApp.User{})
  end

  test "without read_repo reads use primary repo" do
    assert TestApp.UsersWithoutReplica.list_users() == [:from_write_repo]
    assert TestApp.UsersWithoutReplica.get_user(1) == :from_write_repo
  end

  test "invalid read_repo raises" do
    assert_raise ArgumentError, ~r/:read_repo/, fn ->
      defmodule InvalidReadRepo do
        use Contexted.CRUD,
          repo: TestApp.Repo,
          schema: TestApp.User,
          read_repo: :invalid
      end
    end
  end
end

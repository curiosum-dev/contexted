defmodule Contexted.CRUDTest do
  use ExUnit.Case

  defmodule User do
    defstruct [:id]
    def changeset(struct, _attrs), do: struct
  end

  defmodule WriteRepo do
    def all(_queryable), do: [:from_write_repo]
    def get(_queryable, _id), do: :from_write_repo
    def get!(_queryable, _id), do: :from_write_repo
    def insert(record), do: {:ok, {:write, record}}
    def insert!(record), do: {:write, record}
    def update(record), do: {:ok, {:write, record}}
    def update!(record), do: {:write, record}
    def delete(record), do: {:ok, {:write, record}}
    def delete!(record), do: {:write, record}
    def replica, do: Contexted.CRUDTest.ReadRepo
  end

  defmodule ReadRepo do
    def all(_queryable), do: [:from_read_repo]
    def get(_queryable, _id), do: :from_read_repo
    def get!(_queryable, _id), do: :from_read_repo
  end

  defmodule WithReadRepo do
    use Contexted.CRUD,
      repo: WriteRepo,
      schema: User,
      read_repo: {WriteRepo, :replica}
  end

  defmodule WithoutReadRepo do
    use Contexted.CRUD,
      repo: WriteRepo,
      schema: User
  end

  test "read_repo MFA routes list/get to replica repo" do
    assert WithReadRepo.list_users() == [:from_read_repo]
    assert WithReadRepo.get_user(1) == :from_read_repo
    assert WithReadRepo.get_user!(1) == :from_read_repo
  end

  test "writes still use primary repo" do
    assert {:ok, {:write, %User{}}} = WithReadRepo.create_user()
    assert {:write, %User{}} = WithReadRepo.create_user!(%User{id: 1})
    assert {:ok, {:write, %User{}}} = WithReadRepo.update_user(%User{})
    assert {:write, %User{}} = WithReadRepo.update_user!(%User{})
    assert {:ok, {:write, %User{}}} = WithReadRepo.delete_user(%User{})
    assert {:write, %User{}} = WithReadRepo.delete_user!(%User{})
  end

  test "without read_repo reads use primary repo" do
    assert WithoutReadRepo.list_users() == [:from_write_repo]
    assert WithoutReadRepo.get_user(1) == :from_write_repo
  end

  test "invalid read_repo raises" do
    assert_raise ArgumentError, ~r/:read_repo/, fn ->
      defmodule InvalidReadRepo do
        use Contexted.CRUD,
          repo: WriteRepo,
          schema: User,
          read_repo: :invalid
      end
    end
  end
end

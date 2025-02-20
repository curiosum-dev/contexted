defmodule Contexted.TestApp.Repo.Migrations.CreateTestTables do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string, null: false
      timestamps()
    end

    create table(:subcategories) do
      add :name, :string, null: false
      add :category_id, references(:categories, on_delete: :delete_all), null: false
      timestamps()
    end

    create table(:items) do
      add :name, :string, null: false
      add :serial_number, :string, null: false
      add :subcategory_id, references(:subcategories, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:categories, [:name])
    create unique_index(:subcategories, [:category_id, :name])
    create unique_index(:items, [:serial_number])
    create index(:items, [:subcategory_id])
  end
end

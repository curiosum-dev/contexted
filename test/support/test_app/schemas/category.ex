defmodule Contexted.TestApp.Category do
  @moduledoc false
  use Ecto.Schema
  use Contexted.Schema.CounterFields
  import Ecto.Changeset
  import Ecto.Schema

  schema "categories" do
    field :name, :string
    has_many :subcategories, Contexted.TestApp.Subcategory
    has_many :items, through: [:subcategories, :items]

    field :subcategories_count, :integer, virtual: true, default: 0
    field :items_count, :integer, virtual: true, default: 0

    timestamps()
  end

  def __counter_fields__, do: [:subcategories, :items]

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end

defmodule Contexted.TestApp.Category do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    has_many :subcategories, Contexted.TestApp.Subcategory
    timestamps()
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint([:name])
  end
end

defmodule Contexted.TestApp.Subcategory do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "subcategories" do
    field :name, :string
    belongs_to :category, Contexted.TestApp.Category
    has_many :items, Contexted.TestApp.Item
    timestamps()
  end

  def changeset(subcategory, attrs) do
    subcategory
    |> cast(attrs, [:name, :category_id])
    |> validate_required([:name, :category_id])
    |> assoc_constraint(:category)
    |> unique_constraint([:category_id, :name])
  end
end

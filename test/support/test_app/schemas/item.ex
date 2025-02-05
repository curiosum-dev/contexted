defmodule Contexted.TestApp.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :name, :string
    field :serial_number, :string
    belongs_to :subcategory, Contexted.TestApp.Subcategory
    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :serial_number, :subcategory_id])
    |> validate_required([:name, :serial_number, :subcategory_id])
    |> validate_length(:serial_number, max: 10)
    |> assoc_constraint(:subcategory)
    |> unique_constraint([:serial_number])
  end
end

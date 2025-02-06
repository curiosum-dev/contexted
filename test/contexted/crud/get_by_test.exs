defmodule Contexted.CRUD.GetByTest do
  use Contexted.DataCase
  doctest Contexted.CRUD

  alias Contexted.TestApp.{Category, Item, Subcategory}
  alias Contexted.TestApp.Contexts.ItemContext

  import Contexted.TestRecords
  import Ecto.Query
  setup [:test_records]

  describe "get_*_by/1" do
    test ~s{get_item_by(name: "Item 1.1.1")}, %{items: items} do
      assert ItemContext.get_item_by(name: "Item 1.1.1") ==
               items |> Enum.find(&(&1.name == "Item 1.1.1"))
    end

    test ~s{get_item_by(name: "Item 1.1.1", preload: :subcategory)} do
      assert %Item{subcategory: %Subcategory{name: "Subcategory 1.1"}} =
               ItemContext.get_item_by(name: "Item 1.1.1", preload: :subcategory)
    end

    test ~s{get_item_by(name: "Item 1.1.1", preload: [subcategory: :category])} do
      assert %Item{
               subcategory: %Subcategory{
                 name: "Subcategory 1.1",
                 category: %Category{name: "Category 1"}
               }
             } =
               ItemContext.get_item_by(name: "Item 1.1.1", preload: [subcategory: :category])
    end

    test ~s{get_item_by(from(i in Item, where: like(i.name, "Item 1.1.%") and i.serial_number == "1234567890"))} do
      assert %Item{name: "Item 1.1.1"} =
               ItemContext.get_item_by(
                 from(i in Item,
                   where: like(i.name, "Item 1.1.%") and i.serial_number == "1234567890"
                 )
               )
    end

    test ~s{get_item_by(from(i in Item, where: i.serial_number == "nonexistent"))} do
      assert nil ==
               ItemContext.get_item_by(from(i in Item, where: i.serial_number == "nonexistent"))
    end
  end

  describe("get_*_by!/1") do
    test ~s{get_item_by!(name: "Item 1.1.1")}, %{items: items} do
      assert ItemContext.get_item_by!(name: "Item 1.1.1") ==
               items |> Enum.find(&(&1.name == "Item 1.1.1"))
    end

    test ~s{get_item_by!(name: "Item 1.1.1", preload: :subcategory)} do
      assert %Item{subcategory: %Subcategory{name: "Subcategory 1.1"}} =
               ItemContext.get_item_by!(name: "Item 1.1.1", preload: :subcategory)
    end

    test ~s{get_item_by!(name: "Item 1.1.1", preload: [subcategory: :category])} do
      assert %Item{
               subcategory: %Subcategory{
                 name: "Subcategory 1.1",
                 category: %Category{name: "Category 1"}
               }
             } =
               ItemContext.get_item_by!(name: "Item 1.1.1", preload: [subcategory: :category])
    end

    test ~s{get_item_by!(from(i in Item, where: like(i.name, "Item 1.1.%") and i.serial_number == "1234567890"))} do
      assert %Item{name: "Item 1.1.1"} =
               ItemContext.get_item_by!(
                 from(i in Item,
                   where: like(i.name, "Item 1.1.%") and i.serial_number == "1234567890"
                 )
               )
    end

    test "get_item_by!(from(i in Item, where: i.serial_number == \"nonexistent\"))" do
      assert_raise Ecto.NoResultsError, fn ->
        ItemContext.get_item_by!(from(i in Item, where: i.serial_number == "nonexistent"))
      end
    end
  end

  describe("get_*_by/2") do
    test ~s{get_item_by(from(i in Item, where: like(i.name, "Item 1.1.%") and i.serial_number == "1234567890"), preload: [subcategory: :category])} do
      assert %Item{
               name: "Item 1.1.1",
               subcategory: %Subcategory{
                 name: "Subcategory 1.1",
                 category: %Category{name: "Category 1"}
               }
             } =
               ItemContext.get_item_by(
                 from(i in Item,
                   where: like(i.name, "Item 1.1.%") and i.serial_number == "1234567890"
                 ),
                 preload: [subcategory: :category]
               )
    end
  end

  describe("get_*_by!/2") do
    test ~s{get_item_by!(from(i in Item, where: like(i.name, "Item 1.1.%") and i.serial_number == "1234567890"), preload: [subcategory: :category])} do
      assert %Item{
               name: "Item 1.1.1",
               subcategory: %Subcategory{
                 name: "Subcategory 1.1",
                 category: %Category{name: "Category 1"}
               }
             } =
               ItemContext.get_item_by!(
                 from(i in Item,
                   where: like(i.name, "Item 1.1.%") and i.serial_number == "1234567890"
                 ),
                 preload: [subcategory: :category]
               )
    end
  end
end

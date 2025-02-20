defmodule Contexted.CRUD.CountTest do
  use Contexted.DataCase

  alias Contexted.TestApp.Contexts.CategoryContext

  setup :test_records

  describe "list with count" do
    test "counts associations", %{categories: [category1, category2]} do
      categories = CategoryContext.list_categories(count: [:subcategories, :items])

      assert length(categories) == 2

      category1_result = Enum.find(categories, &(&1.id == category1.id))
      assert category1_result.subcategories_count == 2
      assert category1_result.items_count == 4

      category2_result = Enum.find(categories, &(&1.id == category2.id))
      assert category2_result.subcategories_count == 2
      assert category2_result.items_count == 4
    end

    test "counts associations when passing Ecto.Query", %{categories: [category1, category2]} do
      query = from(c in Contexted.TestApp.Category)
      categories = CategoryContext.list_categories(query, count: [:subcategories, :items])

      assert length(categories) == 2

      category1_result = Enum.find(categories, &(&1.id == category1.id))
      assert category1_result.subcategories_count == 2
      assert category1_result.items_count == 4

      category2_result = Enum.find(categories, &(&1.id == category2.id))
      assert category2_result.subcategories_count == 2
      assert category2_result.items_count == 4
    end

    test "counts associations when passing Ecto.Query with conditions", %{
      categories: [category1, _category2]
    } do
      query = from(c in Contexted.TestApp.Category, where: c.id == ^category1.id)
      categories = CategoryContext.list_categories(query, count: [:subcategories, :items])

      assert length(categories) == 1
      [category] = categories

      assert category.subcategories_count == 2
      assert category.items_count == 4
    end

    test "counts associations with conditions", %{categories: [category1, _category2]} do
      categories =
        CategoryContext.list_categories(
          id: category1.id,
          count: [:subcategories, :items]
        )

      assert length(categories) == 1
      [category] = categories

      assert category.subcategories_count == 2
      assert category.items_count == 4
    end

    test "counts associations with order_by", %{categories: [category1, category2]} do
      categories =
        CategoryContext.list_categories(
          count: [:subcategories, :items],
          order_by: [desc: :id]
        )

      assert length(categories) == 2
      [first, second] = categories

      assert first.id == category2.id
      assert first.subcategories_count == 2
      assert first.items_count == 4

      assert second.id == category1.id
      assert second.subcategories_count == 2
      assert second.items_count == 4
    end
  end

  describe "get with count" do
    test "counts associations", %{categories: [category1, _category2]} do
      category = CategoryContext.get_category(category1.id, count: [:subcategories, :items])

      assert category.subcategories_count == 2
      assert category.items_count == 4
    end

    test "counts associations with preload", %{categories: [category1, _category2]} do
      category =
        CategoryContext.get_category(
          category1.id,
          count: [:subcategories, :items],
          preload: [:subcategories]
        )

      assert category.subcategories_count == 2
      assert category.items_count == 4
      assert length(category.subcategories) == 2
    end
  end

  describe "get_by with count" do
    test "counts associations", %{categories: [category1, _category2]} do
      category =
        CategoryContext.get_category_by(
          name: category1.name,
          count: [:subcategories, :items]
        )

      assert category.subcategories_count == 2
      assert category.items_count == 4
    end

    test "counts associations with preload", %{categories: [category1, _category2]} do
      category =
        CategoryContext.get_category_by(
          name: category1.name,
          count: [:subcategories, :items],
          preload: [:subcategories]
        )

      assert category.subcategories_count == 2
      assert category.items_count == 4
      assert length(category.subcategories) == 2
    end
  end
end

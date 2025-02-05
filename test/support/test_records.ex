defmodule Contexted.TestRecords do
  alias Contexted.TestApp.Category
  alias Contexted.TestApp.Subcategory
  alias Contexted.TestApp.Item
  alias Contexted.TestApp.Repo

  def test_records(context) do
    [category1, category2] =
      categories = [
        Repo.insert!(%Category{name: "Category 1"}),
        Repo.insert!(%Category{name: "Category 2"})
      ]

    [subcategory1, subcategory2, subcategory3, subcategory4] =
      subcategories = [
        Repo.insert!(%Subcategory{name: "Subcategory 1.1", category_id: category1.id}),
        Repo.insert!(%Subcategory{name: "Subcategory 1.2", category_id: category1.id}),
        Repo.insert!(%Subcategory{name: "Subcategory 2.1", category_id: category2.id}),
        Repo.insert!(%Subcategory{name: "Subcategory 2.2", category_id: category2.id})
      ]

    items = [
      Repo.insert!(%Item{
        name: "Item 1.1.1",
        serial_number: "1234567890",
        subcategory_id: subcategory1.id
      }),
      Repo.insert!(%Item{
        name: "Item 1.1.2",
        serial_number: "1234567891",
        subcategory_id: subcategory1.id
      }),
      Repo.insert!(%Item{
        name: "Item 1.2.1",
        serial_number: "1234567892",
        subcategory_id: subcategory2.id
      }),
      Repo.insert!(%Item{
        name: "Item 1.2.2",
        serial_number: "1234567893",
        subcategory_id: subcategory2.id
      }),
      Repo.insert!(%Item{
        name: "Item 2.1.1",
        serial_number: "1234567894",
        subcategory_id: subcategory3.id
      }),
      Repo.insert!(%Item{
        name: "Item 2.1.2",
        serial_number: "1234567895",
        subcategory_id: subcategory3.id
      }),
      Repo.insert!(%Item{
        name: "Item 2.2.1",
        serial_number: "1234567896",
        subcategory_id: subcategory4.id
      }),
      Repo.insert!(%Item{
        name: "Item 2.2.2",
        serial_number: "1234567897",
        subcategory_id: subcategory4.id
      })
    ]

    {:ok,
     Map.merge(context, %{
       categories: categories,
       subcategories: subcategories,
       items: items
     })}
  end
end

defmodule Contexted.TestApp.Contexts.CategoryContext do
  use Contexted.CRUD,
    repo: Contexted.TestApp.Repo,
    schema: Contexted.TestApp.Category,
    plural_resource_name: "categories"
end

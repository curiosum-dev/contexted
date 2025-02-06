defmodule Contexted.TestApp.Contexts.SubcategoryContext do
  @moduledoc false
  use Contexted.CRUD,
    repo: Contexted.TestApp.Repo,
    schema: Contexted.TestApp.Subcategory,
    plural_resource_name: "subcategories"
end

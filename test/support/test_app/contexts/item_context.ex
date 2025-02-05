defmodule Contexted.TestApp.Contexts.ItemContext do
  use Contexted.CRUD,
    repo: Contexted.TestApp.Repo,
    schema: Contexted.TestApp.Item,
    plural_resource_name: "items"
end

defmodule Context.Subcontext do
  @moduledoc """
  The `Context.Subcontext` module generates common CRUD functions for a context, similar to `mix phx gen context`.

  Use this module in your context or subcontext by calling
  ```elixr
  use Context.Subcontext,
    repo: # here goes the app repo,
    schema: # here goes the subcontext schema,
    exclude: # list of excluded functions,
    resource_name_plural: # plural form of resource name
  ```

  ## Options

  - `:repo` - The Ecto repository module used for database operations (required).
  - `:schema` - The Ecto schema module used for the resource (required).
  - `:exclude` - A list of atoms representing the functions to be excluded from generation (optional).
  - `:resource_name_plural` - A custom plural version of the resource name to be used in function names (optional). If not provided, singular version with 's' ending will be used to generate list function.

  ## Usage

  ```elixir
  defmodule MyApp.Accounts do
    use Context.Subcontext,
      repo: MyApp.Repo,
      schema: MyApp.Accounts.User,
      exclude: [:delete],
      resource_name_plural: "users"
  end
  ```

  This sample usage will generate all CRUD functions except for delete_user/1.

  ## Generated Functions

  The following functions are generated by default. Any of them can be excluded by adding their atom to the :exclude option.

  - list_RESOURCES - Lists all resources in the schema.
  - get_RESOURCE - Retrieves a resource by its ID. Returns nil if not found.
  - get_RESOURCE! - Retrieves a resource by its ID. Raises an error if not found.
  - create_RESOURCE - Creates a new resource with the provided attributes. Returns an :ok tuple with the resource or an :error tuple with changeset.
  - create_RESOURCE! - Creates a new resource with the provided attributes. Raises an error if creation fails.
  - update_RESOURCE - Updates an existing resource with the provided attributes. Returns an :ok tuple with the resource or an :error tuple with changeset.
  - update_RESOURCE! - Updates an existing resource with the provided attributes. Raises an error if update fails.
  - delete_RESOURCE - Deletes an existing resource. Returns an :ok tuple with the resource or an :error tuple with changeset.
  - delete_RESOURCE! - Deletes an existing resource. Raises an error if delete fails.

  RESOURCE and RESOURCES will be replaced by the singular and plural forms of the resource name.
  """

  defmacro __using__(opts) do
    # Expanding opts
    opts = Enum.map(opts, fn {key, val} -> {key, Macro.expand(val, __CALLER__)} end)

    repo = Keyword.fetch!(opts, :repo)
    schema = Keyword.fetch!(opts, :schema)

    exclude = Keyword.get(opts, :exclude, [])
    resource_name_plural = Keyword.get(opts, :resource_plural_name, nil)

    resource_name = schema |> Module.split() |> List.last() |> Macro.underscore()

    resource_name_plural =
      if resource_name_plural, do: resource_name_plural, else: "#{resource_name}s"

    quote bind_quoted: [
            repo: repo,
            schema: schema,
            exclude: exclude,
            resource_name: resource_name,
            resource_name_plural: resource_name_plural
          ] do
      unless :list in exclude do
        function_name = String.to_atom("list_#{resource_name_plural}")

        def unquote(function_name)() do
          unquote(schema)
          |> unquote(repo).all()
        end
      end

      unless :get in exclude do
        function_name = String.to_atom("get_#{resource_name}")

        def unquote(function_name)(id) do
          unquote(schema)
          |> unquote(repo).get(id)
        end

        function_name = String.to_atom("get_#{resource_name}!")

        def unquote(function_name)(id) do
          unquote(schema)
          |> unquote(repo).get!(id)
        end
      end

      unless :create in exclude do
        function_name = String.to_atom("create_#{resource_name}")

        def unquote(function_name)(attrs \\ %{}) do
          %unquote(schema){}
          |> unquote(schema).changeset(attrs)
          |> unquote(repo).insert()
        end

        function_name = String.to_atom("create_#{resource_name}!")

        def unquote(function_name)(attrs \\ %{}) do
          %unquote(schema){}
          |> unquote(schema).changeset(attrs)
          |> unquote(repo).insert!()
        end
      end

      unless :update in exclude do
        function_name = String.to_atom("update_#{resource_name}")

        def unquote(function_name)(record, attrs \\ %{}) do
          record
          |> unquote(schema).changeset(attrs)
          |> unquote(repo).update()
        end

        function_name = String.to_atom("update_#{resource_name}!")

        def unquote(function_name)(record, attrs \\ %{}) do
          record
          |> unquote(schema).changeset(attrs)
          |> unquote(repo).update!()
        end
      end

      unless :delete in exclude do
        function_name = String.to_atom("delete_#{resource_name}")

        def unquote(function_name)(record) do
          record
          |> unquote(repo).delete()
        end

        function_name = String.to_atom("delete_#{resource_name}!")

        def unquote(function_name)(record) do
          record
          |> unquote(repo).delete!()
        end
      end

      unless :change in exclude do
        function_name = String.to_atom("change_#{resource_name}")

        def unquote(function_name)(record, attrs \\ %{}) do
          record
          |> unquote(schema).changeset(attrs)
        end
      end
    end
  end
end

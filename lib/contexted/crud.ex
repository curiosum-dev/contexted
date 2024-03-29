defmodule Contexted.CRUD do
  @moduledoc """
  The `Contexted.CRUD` module generates common [CRUD](https://pl.wikipedia.org/wiki/CRUD) (Create, Read, Update, Delete) functions for a context, similar to what `mix phx gen context` task generates.

  ## Options

  - `:repo` - The Ecto repository module used for database operations (required)
  - `:schema` - The Ecto schema module representing the resource that these CRUD operations will be generated for (required)
  - `:exclude` - A list of atoms representing the functions to be excluded from generation (optional)
  - `:plural_resource_name` - A custom plural version of the resource name to be used in function names (optional). If not provided, singular version with 's' ending will be used to generate list function

  ## Usage

  ```elixir
  defmodule MyApp.Accounts do
    use Contexted.CRUD,
      repo: MyApp.Repo,
      schema: MyApp.Accounts.User,
      exclude: [:delete],
      plural_resource_name: "users"
  end
  ```

  This sample usage will generate all CRUD functions for `MyApp.Accounts.User` resource, excluding `delete_user/1`.

  ## Generated Functions

  The following functions are generated by default. Any of them can be excluded by adding their correspoding atom to the `:exclude` option.

  - `list_{plural resource name}` - Lists all resources in the schema.
  - `get_{resource name}` - Retrieves a resource by its ID. Returns `nil` if not found.
  - `get_{resource name}!` - Retrieves a resource by its ID. Raises an error if not found.
  - `create_{resource name}` - Creates a new resource with the provided attributes. Returns an `:ok` tuple with the resource or an `:error` tuple with changeset.
  - `create_{resource name}!` - Creates a new resource with the provided attributes. Raises an error if creation fails.
  - `update_{resource name}` - Updates an existing resource with the provided attributes. Returns an `:ok` tuple with the resource or an `:error` tuple with changeset.
  - `update_{resource name}!` - Updates an existing resource with the provided attributes. Raises an error if update fails.
  - `delete_{resource name}` - Deletes an existing resource. Returns an `:ok` tuple with the resource or an `:error` tuple with changeset.
  - `delete_{resource name}!` - Deletes an existing resource. Raises an error if delete fails.
  - `change_{resource name}` - Returns changeset for given resource.

  {resource name} and {plural resource name} will be replaced by the singular and plural forms of the resource name.
  """

  defmacro __using__(opts) do
    # Expanding opts
    opts = Enum.map(opts, fn {key, val} -> {key, Macro.expand(val, __CALLER__)} end)

    repo = Keyword.fetch!(opts, :repo)
    schema = Keyword.fetch!(opts, :schema)

    exclude = Keyword.get(opts, :exclude, [])
    plural_resource_name = Keyword.get(opts, :plural_resource_name, nil)

    resource_name = schema |> Module.split() |> List.last() |> Macro.underscore()

    plural_resource_name =
      if plural_resource_name, do: plural_resource_name, else: "#{resource_name}s"

    # credo:disable-for-next-line Credo.Check.Refactor.LongQuoteBlocks
    quote bind_quoted: [
            repo: repo,
            schema: schema,
            exclude: exclude,
            resource_name: resource_name,
            plural_resource_name: plural_resource_name
          ] do
      unless :list in exclude do
        function_name = String.to_atom("list_#{plural_resource_name}")

        @doc """
        Returns a list of all #{plural_resource_name} from the database.

        ## Examples

            iex> list_#{plural_resource_name}()
            [%#{Macro.camelize(resource_name)}{}, ...]
        """
        @spec unquote(function_name)() :: [%unquote(schema){}]
        def unquote(function_name)() do
          unquote(schema)
          |> unquote(repo).all()
        end
      end

      unless :get in exclude do
        function_name = String.to_atom("get_#{resource_name}")

        @doc """
        Retrieves a single #{resource_name} by its ID from the database. Returns nil if the #{resource_name} is not found.

        ## Examples

            iex> get_#{resource_name}(id)
            %#{Macro.camelize(resource_name)}{} or nil
        """

        @spec unquote(function_name)(integer() | String.t()) :: %unquote(schema){} | nil
        def unquote(function_name)(id) do
          unquote(schema)
          |> unquote(repo).get(id)
        end

        function_name = String.to_atom("get_#{resource_name}!")

        @doc """
        Retrieves a single #{resource_name} by its ID from the database. Raises an error if the #{resource_name} is not found.

        ## Examples

            iex> get_#{resource_name}!(id)
            %#{Macro.camelize(resource_name)}{} or raises Ecto.NoResultsError
        """

        @spec unquote(function_name)(integer() | String.t()) :: %unquote(schema){}
        def unquote(function_name)(id) do
          unquote(schema)
          |> unquote(repo).get!(id)
        end
      end

      unless :create in exclude do
        function_name = String.to_atom("create_#{resource_name}")

        @doc """
        Creates a new #{resource_name} with the provided attributes.

        Returns an `:ok` tuple with the #{resource_name} if successful, or an `:error` tuple with a changeset if not.

        ## Examples

            iex> create_#{resource_name}(attrs)
            {:ok, %#{Macro.camelize(resource_name)}{}} or {:error, Ecto.Changeset{}}
        """

        @spec unquote(function_name)(map()) :: {:ok, %unquote(schema){}} | {:error, map()}
        def unquote(function_name)(attrs \\ %{}) do
          %unquote(schema){}
          |> unquote(schema).changeset(attrs)
          |> unquote(repo).insert()
        end

        function_name = String.to_atom("create_#{resource_name}!")

        @doc """
        Creates a new #{resource_name} with the provided attributes.

        Returns the #{resource_name} if successful, or raises an error if not.

        ## Examples

            iex> create_#{resource_name}!(attrs)
            %#{Macro.camelize(resource_name)}{} or raises Ecto.StaleEntryError
        """

        @spec unquote(function_name)(map()) :: %unquote(schema){}
        def unquote(function_name)(attrs \\ %{}) do
          %unquote(schema){}
          |> unquote(schema).changeset(attrs)
          |> unquote(repo).insert!()
        end
      end

      unless :update in exclude do
        function_name = String.to_atom("update_#{resource_name}")

        @doc """
        Updates an existing #{resource_name} with the provided attributes.

        Returns an `:ok` tuple with the updated #{resource_name} if successful, or an `:error` tuple with a changeset if not.

        ## Examples

            iex> update_#{resource_name}(#{resource_name}, attrs)
            {:ok, %#{Macro.camelize(resource_name)}{}} or {:error, Ecto.Changeset{}}
        """

        @spec unquote(function_name)(%unquote(schema){}, map()) ::
                {:ok, %unquote(schema){}} | {:error, map()}
        def unquote(function_name)(record, attrs \\ %{}) do
          record
          |> unquote(schema).changeset(attrs)
          |> unquote(repo).update()
        end

        function_name = String.to_atom("update_#{resource_name}!")

        @doc """
        Updates an existing #{resource_name} with the provided attributes.

        Returns the updated #{resource_name} if successful, or raises an error if not.

        ## Examples

            iex> update_#{resource_name}!(#{resource_name}, attrs)
            %#{Macro.camelize(resource_name)}{} or raises Ecto.StaleEntryError
        """

        @spec unquote(function_name)(%unquote(schema){}, map()) :: %unquote(schema){}
        def unquote(function_name)(record, attrs \\ %{}) do
          record
          |> unquote(schema).changeset(attrs)
          |> unquote(repo).update!()
        end
      end

      unless :delete in exclude do
        function_name = String.to_atom("delete_#{resource_name}")

        @doc """
        Deletes an existing #{resource_name}.

        Returns an `:ok` tuple with the deleted #{resource_name} if successful, or an `:error` tuple with a changeset if not.

        ## Examples

            iex> delete_#{resource_name}(#{resource_name})
            {:ok, %#{Macro.camelize(resource_name)}{}} or {:error, Ecto.Changeset{}}
        """

        @spec unquote(function_name)(%unquote(schema){}) ::
                {:ok, %unquote(schema){}} | {:error, map()}
        def unquote(function_name)(record) do
          record
          |> unquote(repo).delete()
        end

        function_name = String.to_atom("delete_#{resource_name}!")

        @spec unquote(function_name)(%unquote(schema){}) :: {:ok, %unquote(schema){}}
        def unquote(function_name)(record) do
          record
          |> unquote(repo).delete!()
        end
      end

      unless :change in exclude do
        function_name = String.to_atom("change_#{resource_name}")

        @doc """
        Deletes an existing #{resource_name}.

        Returns the deleted #{resource_name} if successful, or raises an error if not.

        ## Examples

            iex> delete_#{resource_name}!(#{resource_name})
            %#{Macro.camelize(resource_name)}{} or raises Ecto.StaleEntryError
        """

        @spec unquote(function_name)(%unquote(schema){}, map()) :: map()
        def unquote(function_name)(record, attrs \\ %{}) do
          record
          |> unquote(schema).changeset(attrs)
        end
      end
    end
  end
end

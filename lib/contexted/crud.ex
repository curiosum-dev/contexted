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

  - `list_{plural resource name}` - Lists all resources in the schema, optionally filtered by a query or condition list, or preloaded with associations.
  - `get_{resource name}` - Retrieves a resource by its ID, optionally preloaded with associations. Returns `nil` if not found.
  - `get_{resource name}!` - Retrieves a resource by its ID, optionally preloaded with associations. Raises an error if not found.
  - `get_{resource name}_by` - Retrieves a resource by a query or condition list, optionally preloaded with associations. Returns `nil` if not found.
  - `get_{resource name}_by!` - Retrieves a resource by a query or condition list, optionally preloaded with associations. Raises an error if not found.
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
      import Contexted.QueryBuilder

      unless :list in exclude do
        function_name = String.to_atom("list_#{plural_resource_name}")

        @doc """
        Returns a list of all #{plural_resource_name} from the database.

        ## Arguments

        The function accepts several argument patterns:

        - No arguments: Returns all records
        - Single argument:
          - `Ecto.Query` or schema module: Uses this as the base query
          - Keyword list: Exact, possibly nested, match conditions (translated to Ecto queries under the hood) and options (e.g. preload)
        - Two arguments:
          - Query + options: Uses query and applies options like preloads

        ## Options

        - `:preload` - Preloads associations. Can be an atom or list of atoms.

        ## Examples

            iex> list_#{plural_resource_name}()
            [%#{Macro.camelize(resource_name)}{}, ...]

            iex> list_#{plural_resource_name}(from r in #{schema}, limit: 10)
            [%#{Macro.camelize(resource_name)}{}, ...]

            iex> list_#{plural_resource_name}(preload: :associated)
            [%#{Macro.camelize(resource_name)}{associated: ...}, ...]

            iex> list_#{plural_resource_name}(status: :active, preload: [:associated])
            [%#{Macro.camelize(resource_name)}{associated: ...}, ...]

            iex> list_#{plural_resource_name}(#{schema} |> limit(10), preload: [:associated])
            [%#{Macro.camelize(resource_name)}{associated: ...}, ...]
        """

        def unquote(function_name)() do
          # No args: list all resources based on the schema
          unquote(schema)
          |> unquote(repo).all()
        end

        def unquote(function_name)(query) when is_struct(query, Ecto.Query) or is_atom(query) do
          # One arg: list all resources based on the query
          query
          |> unquote(repo).all()
        end

        def unquote(function_name)(conditions_and_opts) do
          # One arg: list all resources based on the query
          {opts, conditions} = Keyword.split(conditions_and_opts, [:preload])

          build_query(unquote(schema), conditions)
          |> unquote(repo).all()
          |> unquote(repo).preload(opts[:preload] || [])
        end

        def unquote(function_name)(query, opts)
            when (is_struct(query, Ecto.Query) or is_atom(query)) and is_list(opts) do
          # Two args: list all resources based on the query and opts
          query
          |> unquote(repo).all()
          |> unquote(repo).preload(opts[:preload] || [])
        end
      end

      unless :get in exclude do
        function_name = String.to_atom("get_#{resource_name}")

        @doc """
        Retrieves a single #{resource_name} by its ID from the database. Returns nil if the #{resource_name} is not found.

        If a list of preloads is provided, it will be used to preload the #{resource_name}.
        Preloads can be an atom or a list of atoms.

        ## Examples

            iex> get_#{resource_name}(id)
            %#{Macro.camelize(resource_name)}{} or nil

            iex> get_#{resource_name}(id, preload: [:associated])
            %#{Macro.camelize(resource_name)}{associated: ...} or nil
        """

        @spec unquote(function_name)(integer() | String.t(), keyword()) ::
                %unquote(schema){} | nil
        def unquote(function_name)(id, opts \\ []) when is_list(opts) do
          unquote(schema)
          |> unquote(repo).get(id)
          |> case do
            nil -> nil
            record -> unquote(repo).preload(record, opts[:preload] || [])
          end
        end

        function_name = String.to_atom("get_#{resource_name}!")

        @doc """
        Retrieves a single #{resource_name} by its ID from the database. Raises an error if the #{resource_name} is not found.

        If a list of preloads is provided, it will be used to preload the #{resource_name}.
        Preloads can be an atom or a list of atoms.

        ## Examples

            iex> get_#{resource_name}!(id)
            %#{Macro.camelize(resource_name)}{} or raises Ecto.NoResultsError

            iex> get_#{resource_name}!(id, preload: [:associated])
            %#{Macro.camelize(resource_name)}{associated: ...} or raises Ecto.NoResultsError
        """

        @spec unquote(function_name)(integer() | String.t(), keyword()) :: %unquote(schema){}
        def unquote(function_name)(id, preloads \\ [])
            when is_list(preloads) or is_atom(preloads) do
          unquote(schema)
          |> unquote(repo).get!(id)
          |> unquote(repo).preload(preloads)
        end
      end

      unless :get_by in exclude do
        function_name = String.to_atom("get_#{resource_name}_by")

        defp maybe_preload(nil, _preload), do: nil
        defp maybe_preload(record, nil), do: record
        defp maybe_preload(record, preload), do: unquote(repo).preload(record, preload)

        @doc """
        Retrieves a single #{resource_name} by either an Ecto.Query or a map/keyword list of conditions from the database. Returns nil if the #{resource_name} is not found.

        ## Arguments

        The function accepts several argument patterns:

        - Single argument:
          - `Ecto.Query` or schema module: Uses this as the base query
          - Keyword list or map: Used as conditions and options (e.g. preload)
        - Two arguments:
          - Query + options: Uses query and applies options like preloads
          - Conditions + options: Applies conditions and options separately

        ## Options

        - `:preload` - Preloads associations. Can be an atom or list of atoms.

        ## Examples

            # Exact match condition list
            iex> get_#{resource_name}_by(status: "active")
            %#{Macro.camelize(resource_name)}{} or nil

            # Exact match condition list + preload
            iex> get_#{resource_name}_by(status: "active", preload: :associated)
            %#{Macro.camelize(resource_name)}{associated: ...} or nil

            # Exact match condition list with a nested condition in a join table + preload
            iex> get_#{resource_name}_by(associated: [id: 1], preload: :associated)
            %#{Macro.camelize(resource_name)}{associated: ...} or nil

            # Query
            iex> get_#{resource_name}_by(from r in #{schema}, where: r.status == "active")
            %#{Macro.camelize(resource_name)}{} or nil

            # Query + preload
            iex> get_#{resource_name}_by(from r in #{schema}, where: r.status == "active", preload: :associated)
            %#{Macro.camelize(resource_name)}{associated: ...} or nil

            # Query + preload
            iex> get_#{resource_name}_by(#{schema} |> where(...), preload: [:associated])
            %#{Macro.camelize(resource_name)}{associated: ...} or nil
        """

        @spec unquote(function_name)(Ecto.Queryable.t(), keyword()) :: %unquote(schema){}
        def unquote(function_name)(query, opts)
            when is_struct(query, Ecto.Query) or is_atom(query) do
          # Two args: get resource based on the query, with preloads
          query
          |> unquote(repo).one()
          |> maybe_preload(opts[:preload])
        end

        @spec unquote(function_name)(Ecto.Queryable.t()) :: %unquote(schema){}
        def unquote(function_name)(query) when is_struct(query, Ecto.Query) or is_atom(query) do
          # One arg: get resource based on the query
          query
          |> unquote(repo).one()
        end

        @spec unquote(function_name)(map() | keyword()) :: %unquote(schema){}
        def unquote(function_name)(conditions_and_opts)
            when is_list(conditions_and_opts) or is_map(conditions_and_opts) do
          # One arg: get resource with conditions and preloads
          {opts, conditions} =
            if is_list(conditions_and_opts),
              do: Keyword.split(conditions_and_opts, [:preload]),
              else: {[], conditions_and_opts}

          build_query(unquote(schema), conditions)
          |> unquote(repo).one()
          |> maybe_preload(opts[:preload])
        end

        @spec unquote(function_name)(map() | keyword(), keyword()) :: %unquote(schema){}
        def unquote(function_name)(conditions, preloads) when is_list(preloads) do
          # Two args: get resource with separate conditions and preloads
          build_query(unquote(schema), conditions)
          |> unquote(repo).one()
          |> maybe_preload(preloads[:preload])
        end

        function_name = String.to_atom("get_#{resource_name}_by!")

        @doc """
        Similar to get_#{resource_name}_by/2 but raises Ecto.NoResultsError if no result is found.

        ## Examples

            # Exact match condition list
            iex> get_#{resource_name}_by!(status: "active")
            %#{Macro.camelize(resource_name)}{} or raises Ecto.NoResultsError

            # Exact match condition list + preload
            iex> get_#{resource_name}_by!(status: "active", preload: :associated)
            %#{Macro.camelize(resource_name)}{associated: ...} or raises Ecto.NoResultsError

            # Query
            iex> get_#{resource_name}_by!(from r in #{schema}, where: r.status == "active")
            %#{Macro.camelize(resource_name)}{} or raises Ecto.NoResultsError

            # Query + preload
            iex> get_#{resource_name}_by!(from r in #{schema}, where: r.status == "active", preload: :associated)
            %#{Macro.camelize(resource_name)}{associated: ...} or raises Ecto.NoResultsError

            # Query + preload
            iex> get_#{resource_name}_by!(#{schema} |> where(...), preload: [:associated])
            %#{Macro.camelize(resource_name)}{associated: ...} or raises Ecto.NoResultsError
        """

        @spec unquote(function_name)(Ecto.Queryable.t(), keyword()) :: %unquote(schema){}
        def unquote(function_name)(query, opts)
            when is_struct(query, Ecto.Query) or is_atom(query) do
          # Two args: get resource based on the query, with preloads
          query
          |> unquote(repo).one!()
          |> maybe_preload(opts[:preload])
        end

        @spec unquote(function_name)(Ecto.Queryable.t()) :: %unquote(schema){}
        def unquote(function_name)(query) when is_struct(query, Ecto.Query) or is_atom(query) do
          # One arg: get resource based on the query
          query
          |> unquote(repo).one!()
        end

        @spec unquote(function_name)(map() | keyword()) :: %unquote(schema){}
        def unquote(function_name)(conditions_and_opts)
            when is_list(conditions_and_opts) or is_map(conditions_and_opts) do
          # One arg: get resource with conditions and preloads
          {opts, conditions} =
            if is_list(conditions_and_opts),
              do: Keyword.split(conditions_and_opts, [:preload]),
              else: {[], conditions_and_opts}

          build_query(unquote(schema), conditions)
          |> unquote(repo).one!()
          |> maybe_preload(opts[:preload])
        end

        @spec unquote(function_name)(map() | keyword(), keyword()) :: %unquote(schema){}
        def unquote(function_name)(conditions, preloads) when is_list(preloads) do
          # Two args: get resource with separate conditions and preloads
          build_query(unquote(schema), conditions)
          |> unquote(repo).one!()
          |> maybe_preload(preloads[:preload])
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

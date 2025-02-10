defmodule Contexted.QueryBuilder do
  @moduledoc """
  Builds queries based on conditions defined as keyword lists.

  ## Example

  ```elixir
  query = Contexted.QueryBuilder.build_query(MyApp.Inventory.Item, [
    part_number: "1234567890",
    category: "electronics",
    manufacturer: [name: "Acme"]
  ])

  # This will generate the following query:
  #
  # from i in MyApp.Inventory.Item,
  #   join: m in assoc(i, :manufacturer),
  #   where: i.category == "electronics" and m.name == "Acme" and i.part_number == "1234567890"
  ```
  """
  import Ecto.Query

  @doc """
  Builds a query based on the given schema and conditions.

  Automatically joins associations based on the conditions.

  ## Example

  ```elixir
  query = Contexted.QueryBuilder.build_query(MyApp.Inventory.Item, [
    part_number: "1234567890",
    category: "electronics",
    manufacturer: [name: "Acme"]
  ])

  # This will generate the following query:
  #
  # from i in MyApp.Inventory.Item,
  #   join: m in assoc(i, :manufacturer),
  #   where: i.category == "electronics" and m.name == "Acme" and i.part_number == "1234567890"
  ```
  """
  def build_query(schema, conditions, opts \\ [])

  def build_query(schema, conditions, opts) when is_map(conditions) do
    build_query(schema, Map.to_list(conditions), opts)
  end

  def build_query(schema, conditions, opts) do
    from(r in schema)
    |> then(&if opts[:order_by], do: order_by(&1, ^opts[:order_by]), else: &1)
    |> then(&if opts[:limit], do: limit(&1, ^opts[:limit]), else: &1)
    |> then(&if opts[:offset], do: offset(&1, ^opts[:offset]), else: &1)
    |> traverse_conditions(conditions, [])
  end

  defp traverse_conditions(query, [condition | rest], parent_path) do
    query
    |> join_or_where(condition, parent_path)
    |> traverse_conditions(rest, parent_path)
  end

  defp traverse_conditions(query, [], _parent_path) do
    query
  end

  defp join_or_where(query, {assoc_name, assoc_conditions}, parent_path)
       when is_list(assoc_conditions) do
    new_parent_path = parent_path ++ [assoc_name]
    new_binding_name = join_parent_path(new_parent_path)

    query =
      case parent_path do
        [] ->
          from r in query,
            join: s in assoc(r, ^assoc_name),
            as: ^new_binding_name

        _path ->
          from [{^join_parent_path(parent_path), r}] in query,
            join: s in assoc(r, ^assoc_name),
            as: ^new_binding_name
      end

    query
    |> traverse_conditions(assoc_conditions, new_parent_path)
  end

  defp join_or_where(query, {field, value}, parent_path) do
    case {parent_path, value} do
      {[], nil} ->
        from r in query, where: is_nil(field(r, ^field))

      {[], _} ->
        from r in query, where: field(r, ^field) == ^value

      {_path, nil} ->
        from [{^join_parent_path(parent_path), r}] in query, where: is_nil(field(r, ^field))

      {_path, _} ->
        from [{^join_parent_path(parent_path), r}] in query, where: field(r, ^field) == ^value
    end
  end

  defp join_parent_path(parent_path) do
    Enum.map_join(parent_path, "_", &"#{&1}")
    |> String.to_atom()
  end
end

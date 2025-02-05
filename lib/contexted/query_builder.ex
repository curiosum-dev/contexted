defmodule Contexted.QueryBuilder do
  import Ecto.Query

  def build_query(schema, conditions) do
    from(r in schema)
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

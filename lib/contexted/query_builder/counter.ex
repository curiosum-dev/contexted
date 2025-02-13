defmodule Contexted.QueryBuilder.Counter do
  @moduledoc false
  import Ecto.Query

  # Adds counts to the query for the given associations.
  #
  # The query must have a single from clause with a single binding.
  #
  # The associations must be shallow associations, meaning they are
  # directly associated with the root schema.
  #
  # The counts are added as a new field to the query with the name of the
  # association with "_count" appended.
  #
  # For example, if the query is:
  #
  #     from q in MySchema, join: a in assoc(q, :association)
  #
  # The counts will be added as:
  #
  #     [%MySchema{id: 1, association_count: 10},
  #      %MySchema{id: 2, association_count: 20},
  #      ...]
  #
  # The schema module must have a virtual field named `#{assoc_name}_count`.
  @spec add_counts(Ecto.Query.t(), list(atom())) :: Ecto.Query.t()
  def add_counts(query, counts) when is_list(counts) do
    {base_table, _schema} = query.from.source
    base_table = String.to_atom(base_table)

    counts
    |> Enum.reduce(query, fn counted_assoc_name, query_so_far ->
      validate_shallow_association!(counted_assoc_name)

      count_binding = "#{base_table}_#{counted_assoc_name}_count"
      count_field = :"#{counted_assoc_name}_count"

      # Select counts of currently analyzed association for each record of the base table.
      assoc_counter_subquery =
        from([q] in query)
        |> join(:left, [q], a in assoc(q, ^counted_assoc_name), as: ^count_binding)
        |> group_by([q, {^count_binding, a}], q.id)
        |> select([q, {^count_binding, a}], %{parent_id: q.id, count: count(a)})

      # Join the base table with the counts subquery on the id field.
      query_so_far
      |> join(:left, [q], s in subquery(assoc_counter_subquery),
        as: ^count_binding,
        on: s.parent_id == q.id
      )
      |> select_merge([q, {^count_binding, s}], %{^count_field => s.count})
    end)
  end

  defp validate_shallow_association!(assoc_name) do
    unless is_atom(assoc_name) do
      raise ArgumentError,
            "Preloading counts is not supported for nested assocaitions yet: #{assoc_name}"
    end
  end
end

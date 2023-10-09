defmodule Contexted.ModuleAnalyzer do
  @moduledoc """
  The `Contexted.ModuleAnalyzer` defines utils functions that analyze and extract information from other modules.
  """

  @module_prefix "Elixir."

  @doc """
  Fetches the `@doc` definitions for all functions within the given module.
  """
  @spec get_functions_docs(module()) :: [tuple()]
  def get_functions_docs(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, functions_docs} ->
        Enum.filter(functions_docs, fn
          {{:function, _, _}, _, _, _, _} -> true
          {_, _, _, _, _} -> false
        end)

      _ ->
        []
    end
  end

  @doc """
  Fetches the `@spec` definitions for all functions within the given module.
  """
  @spec get_functions_specs(module()) :: [tuple()]
  def get_functions_specs(module) do
    case Code.Typespec.fetch_specs(module) do
      {:ok, specs} -> specs
      _ -> []
    end
  end

  @doc """
  Finds and returns the `@spec` definition in string format for the specified function name and arity.
  Returns `nil` if the function is not found in the specs.
  """
  @spec get_function_spec([tuple()], atom(), non_neg_integer(), module()) :: String.t() | nil
  def get_function_spec(specs, function_name, arity, module) do
    # Find the spec tuple in the specs
    spec = find_spec(specs, function_name, arity)

    # If spec is found, build the spec expression
    if spec do
      build_spec(spec, module)
    else
      nil
    end
  end

  @doc """
  Finds and returns the `@doc` definition in string format for the specified function name and arity.
  Returns `nil` if the function is not found in the function docs.
  """
  @spec get_function_doc([tuple()], atom(), non_neg_integer()) :: String.t() | nil
  def get_function_doc(functions_docs, name, arity) do
    Enum.find(functions_docs, fn
      {{:function, func_name, func_arity}, _, _, _, _} ->
        func_name == name && func_arity == arity
    end)
    |> case do
      {_, _, _, %{"en" => doc}, _} ->
        "@doc \"\"\"\n#{doc}\n\"\"\""

      _ ->
        nil
    end
  end

  @doc """
  Generates a list of unique argument names based on the given arity.
  """
  @spec generate_random_function_arguments(non_neg_integer()) :: [atom()]
  def generate_random_function_arguments(arity) do
    if arity > 0 do
      Enum.map(0..(arity - 1), &{String.to_atom("arg_#{&1}"), [], nil})
    else
      []
    end
  end

  @spec find_spec([tuple()], atom(), non_neg_integer()) :: tuple() | nil
  defp find_spec(specs, function_name, arity) do
    Enum.find(specs, fn
      {{^function_name, ^arity}, _} -> true
      _ -> false
    end)
  end

  @spec build_spec(tuple(), module()) :: String.t()
  defp build_spec({{function_name, _arity}, spec}, module) do
    {:type, _, :fun, [arg_types, return_type]} = hd(spec)
    arg_types_string = format_arg_types(arg_types, module)
    return_type_string = format_type(return_type, module)

    function_with_args = "#{function_name}(#{arg_types_string})"
    return_value = return_type_string

    "@spec #{function_with_args} :: #{return_value}"
  end

  @spec format_arg_types(tuple(), module()) :: String.t()
  defp format_arg_types({:type, _, :product, []}, _module), do: ""

  defp format_arg_types({:type, _, :product, arg_types}, module) do
    Enum.map_join(arg_types, ",", &format_type(&1, module))
  end

  @spec format_type(tuple(), module()) :: String.t()
  defp format_type({:type, _, :union, types}, module) do
    Enum.map_join(types, " | ", &format_type(&1, module))
  end

  defp format_type({:type, 0, nil, []}, _module), do: "[]"

  defp format_type({:type, _, type_name, _}, _module), do: "#{type_name}()"

  defp format_type({:user_type, _, atom, _}, module) do
    "#{Atom.to_string(module)}.#{Atom.to_string(atom)}()"
  end

  defp format_type({:atom, _, atom}, _module) do
    stringed_atom = Atom.to_string(atom)

    if is_module(stringed_atom) do
      stringed_atom
    else
      ":#{stringed_atom}"
    end
  end

  defp format_type({:remote_type, _, [{:atom, _, module}, {:atom, _, type}, _list]}, _module) do
    if module == :elixir do
      "#{type}()"
    else
      "#{module}.#{type}()"
    end
  end

  @spec is_module(String.t()) :: boolean()
  defp is_module(stringed_atom), do: String.starts_with?(stringed_atom, @module_prefix)
end

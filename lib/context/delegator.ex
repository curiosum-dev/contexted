defmodule Context.Delegator do
  @moduledoc """
  The `Context.Delegator` module provides a macro to delegate all functions defined within a specific module.

  This module can be used to forward all function calls from one module to another, without the need to write
  individual `defdelegate` statements for each function.

  ## Usage

  To use the `delegate_all` macro, simply include it in your module and pass the target module as an argument:

      defmodule MyModule do
        import Context.Delegator

        delegate_all MyTargetModule
      end

  All public functions defined in `MyTargetModule` will now be accessible through `MyModule`.

  Note: This macro should be used with caution, as it may lead to unexpected behaviors if two modules with overlapping function names are delegated.
  """

  alias Context.ModuleAnalyzer

  @doc """
  Delegates all public functions of the given `module` to the module using the macro.

  ## Examples

      defmodule MyModule do
        import Context.Delegator

        delegate_all MyTargetModule
      end

  All public functions defined in `MyTargetModule` will now be accessible through `MyModule`.
  """
  defmacro delegate_all(module) do
    # Ensure the module is an atom
    module =
      case module do
        {:__aliases__, _, _} -> apply(Macro, :expand, [module, __CALLER__])
        _ -> module
      end

    functions_docs = ModuleAnalyzer.get_module_docs(module)
    functions_specs = ModuleAnalyzer.get_module_specs(module)

    # Get the module's public functions
    functions =
      module.__info__(:functions)
      |> Enum.filter(fn {name, arity} -> :erlang.function_exported(module, name, arity) end)
      |> Enum.map(fn {name, arity} ->
        args = ModuleAnalyzer.generate_random_function_arguments(arity)
        doc = ModuleAnalyzer.get_function_doc(functions_docs, name, arity)
        spec = ModuleAnalyzer.get_function_spec(functions_specs, name, arity)

        {name, arity, args, doc, spec}
      end)

    # Generate the defdelegate AST for each function
    delegates =
      Enum.map(functions, fn {name, _arity, args, doc, spec} ->
        quote do
          @doc unquote(doc)
          if unquote(spec), do: unquote(Code.string_to_quoted!(spec))

          defdelegate unquote(name)(unquote_splicing(args)),
            to: unquote(module),
            as: unquote(name)
        end
      end)

    # Combine the generated delegates into a single AST
    quote do
      (unquote_splicing(delegates))
    end
  end
end

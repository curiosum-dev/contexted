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
    module_atom =
      case module do
        {:__aliases__, _, _} -> apply(Macro, :expand, [module, __CALLER__])
        _ -> module
      end

    # Get the module's public functions
    functions =
      module_atom.__info__(:functions)
      |> Enum.filter(fn {name, arity} -> :erlang.function_exported(module_atom, name, arity) end)
      |> Enum.map(fn {name, arity} ->
        args =
          if arity > 0 do
            Enum.map(0..(arity - 1), &{String.to_atom("arg_#{&1}"), [], nil})
          else
            []
          end

        {name, arity, args}
      end)

    # Generate the defdelegate AST for each function
    delegates =
      Enum.map(functions, fn {name, _arity, args} ->
        quote do
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

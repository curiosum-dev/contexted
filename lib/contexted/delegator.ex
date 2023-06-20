defmodule Contexted.Delegator do
  @moduledoc """
  The `Contexted.Delegator` module provides a macro to delegate all functions defined within a specific module.

  This module can be used to forward all function calls from one module to another without the need to write
  individual `defdelegate` statements for each function.

  ## Usage

  To use the `delegate_all` macro, simply include it in your module and pass the target module as an argument:

      defmodule MyContextModule do
        import Contexted.Delegator

        delegate_all MyTargetSubcontextModule
      end

  All public functions defined in `MyTargetSubcontextModule` will now be accessible within `MyContextModule`.

  Note: This macro should be used with caution, as it may lead to unexpected behaviors if two modules with overlapping function names are delegated.

  ## Additional configuration

  The `Contexted.Delegator` module can be used without `Mix.Tasks.Compile.Contexted` as one of the compilers.

  However, if you wish to enable automatic `@doc` and `@spec` generation for delegated functions, you will need to set the following config:

      config :contexted,
        enable_recompilation: true
  """

  alias Contexted.{ModuleAnalyzer, Utils}

  @doc """
  Delegates all public functions of the given module.

  ## Examples

      defmodule MyContextModule do
        import Contexted.Delegator

        delegate_all MyTargetSubcontextModule
      end

  All public functions defined in `MyTargetSubcontextModule` will now be accessible within `MyContextModule`.
  """
  defmacro delegate_all(module) do
    # Ensure the module is an atom
    module =
      case module do
        {:__aliases__, _, _} ->
          Macro.expand(module, __CALLER__)

        _ ->
          module
      end

    functions_docs = ModuleAnalyzer.get_functions_docs(module)
    functions_specs = ModuleAnalyzer.get_functions_specs(module)

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
          if unquote(doc), do: unquote(Code.string_to_quoted!(doc))

          if unquote(spec) && Utils.recompilation_enabled?(),
            do: unquote(Code.string_to_quoted!(spec))

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

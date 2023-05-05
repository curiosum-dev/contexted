defmodule Mix.Tasks.Compile.Context do
  use Mix.Task.Compiler

  alias Context.Tracer

  @moduledoc """
  A custom Elixir compiler task that checks for cross-references between specific modules, known as "contexts".
  """

  @doc """
  Sets the custom compiler tracer to the Context.Tracer module.
  """
  def run(_argv) do
    if recompilation_enabled?() do
      Mix.Task.Compiler.after_compiler(:app, &Tracer.after_compiler/1)
    end

    tracers = Code.get_compiler_option(:tracers)
    Code.put_compiler_option(:tracers, [Tracer | tracers])
  end

  @spec recompilation_enabled? :: boolean()
  defp recompilation_enabled? do
    Application.get_env(:context, :enable_recompilation)
  end
end

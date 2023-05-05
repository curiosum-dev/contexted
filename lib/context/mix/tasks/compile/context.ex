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
    Mix.Task.Compiler.after_compiler(:app, &Tracer.after_compiler/1)

    tracers = Code.get_compiler_option(:tracers)
    Code.put_compiler_option(:tracers, [Tracer | tracers])
  end
end

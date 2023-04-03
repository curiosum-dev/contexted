defmodule Mix.Tasks.Compile.Context do
  use Mix.Task.Compiler

  @moduledoc """
  A custom Elixir compiler task that checks for cross-references between specific modules, known as "contexts".
  """

  @doc """
  Sets the custom compiler tracer to the Context.Tracer module.
  """
  def run(_argv) do
    tracers = Code.get_compiler_option(:tracers)
    Code.put_compiler_option(:tracers, [Context.Tracer | tracers])
  end
end

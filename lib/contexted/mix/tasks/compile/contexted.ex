defmodule Mix.Tasks.Compile.Contexted do
  use Mix.Task.Compiler

  alias Contexted.Tracer

  @moduledoc """
  A custom Elixir compiler task that checks for cross-references between specific modules, known as "contexts".
  """

  @doc """
  Sets the custom compiler tracer to the Contexted.Tracer module.
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
    Application.get_env(:contexted, :enable_recompilation)
  end
end

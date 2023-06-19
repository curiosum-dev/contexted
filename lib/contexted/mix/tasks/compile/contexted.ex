defmodule Mix.Tasks.Compile.Contexted do
  use Mix.Task.Compiler

  alias Contexted.{Tracer, Utils}
  alias Mix.Task.Compiler

  @moduledoc """
  A custom Elixir compiler task that checks for cross-references between specific modules, known as "contexts".
  """

  @contexts Application.compile_env(:contexted, :contexts, [])

  @doc """
  Sets the custom compiler tracer to the Contexted.Tracer module.
  """
  @spec run(any()) :: :ok
  def run(_argv) do
    if Enum.count(@contexts) > 0 do
      if Utils.recompilation_enabled?() do
        Compiler.after_compiler(:app, &Tracer.after_compiler/1)
      end

      tracers = Code.get_compiler_option(:tracers)
      Code.put_compiler_option(:tracers, [Tracer | tracers])
    else
      :ok
    end
  end
end

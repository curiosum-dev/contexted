defmodule Context.Tracer do
  @moduledoc """
  The `Context.Tracer` module provides a set of functions to trace and enforce separation between specific modules, known as "contexts".

  This is useful when you want to ensure that certain modules do not reference each other directly within your application.
  """

  @contexts Application.compile_env(:context, :contexts, [])

  @doc """
  A guard to check if `env.module` and `module` are both in the `contexts` and if they are not equal.

  Usage:

      def some_function(env, module, contexts) when module_mismatch(env, module, contexts) do
        # Function body
      end

  ## Parameters

  - `env`: A map containing the `module` key, which should be checked against the `contexts`.
  - `module`: The module to be checked against the `contexts`.
  - `contexts`: A list of modules that contains both `env.module` and `module`.

  ## Examples

      iex> Guard.module_mismatch(%{module: :foo}, :bar, [:foo, :bar, :baz])
      true

      iex> Guard.module_mismatch(%{module: :foo}, :foo, [:foo, :bar, :baz])
      false
  """
  defguardp module_mismatch(env, module)
            when env.module in @contexts and
                   module in @contexts and
                   env.module != module

  @doc """
  Checks if the provided event is an alias reference between two context modules.

  If so, raises an error with an appropriate message.
  """
  def trace({:alias_reference, _line_details, module}, env) when module_mismatch(env, module) do
    raise_error(env.module, module)
  end

  def trace({:imported_function, _meta, module, _name, _arity}, env)
      when module_mismatch(env, module) do
    raise_error(env.module, module)
  end

  def trace({:require, _meta, module, _opts}, env)
      when module_mismatch(env, module) do
    raise_error(env.module, module)
  end

  def trace({:remote_function, _meta, module, _name, _arity}, env)
      when module_mismatch(env, module) do
    raise_error(env.module, module)
  end

  def trace({:remote_macro, _meta, module, _name, _arity}, env)
      when module_mismatch(env, module) do
    raise_error(env.module, module)
  end

  @doc """
  Ignores other events and returns :ok.
  """
  def trace(_event, _env) do
    :ok
  end

  defp raise_error(module1, module2) do
    raise "You can't reference a #{module1} context within #{module2} context"
  end
end

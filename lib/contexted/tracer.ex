defmodule Contexted.Tracer do
  @moduledoc """
  The `Contexted.Tracer` module provides a set of functions to trace and enforce separation between specific modules, known as "contexts".

  This is useful when you want to ensure that certain modules do not reference each other directly within your application.
  """

  @contexts Application.compile_env(:contexted, :contexts, [])

  @doc """
  Checks if the provided event is an alias reference between two context modules.

  If so, raises an error with an appropriate message.
  """
  @spec trace(tuple(), map()) :: :ok
  def trace({action, _line_details, module}, env) when action in [:alias_reference] do
    verify_modules_mismatch(env.module, module)
  end

  def trace({action, _meta, module, _name, _arity}, env)
      when action in [:imported_function, :remote_function, :remote_macro] do
    verify_modules_mismatch(env.module, module)
  end

  def trace({action, _meta, module, _opts}, env) when action in [:require] do
    verify_modules_mismatch(env.module, module)
  end

  def trace(_event, _env), do: :ok

  @spec after_compiler(tuple()) :: tuple()
  def after_compiler({status, diagnostics}) do
    beam_files_folder = extract_beam_files_folder()
    file_paths = remove_context_beams_and_return_module_paths()

    Kernel.ParallelCompiler.compile_to_path(file_paths, beam_files_folder)

    {status, diagnostics}
  end

  @spec extract_beam_files_folder :: String.t()
  defp extract_beam_files_folder do
    first_context = List.first(@contexts)
    compiled_file_path = :code.which(first_context) |> List.to_string()
    compiled_file_name = Path.basename(compiled_file_path)
    String.replace(compiled_file_path, compiled_file_name, "")
  end

  @spec remove_context_beams_and_return_module_paths :: list(String.t())
  defp remove_context_beams_and_return_module_paths do
    @contexts
    |> Enum.map(fn module ->
      file_path = module.__info__(:compile)[:source] |> List.to_string()

      :code.which(module) |> List.to_string() |> File.rm()

      file_path
    end)
  end

  @spec verify_modules_mismatch(module(), module()) :: :ok
  defp verify_modules_mismatch(analyzed_module, referenced_module) do
    analyzed_context_module = map_module_to_context_module(analyzed_module)
    referenced_context_module = map_module_to_context_module(referenced_module)

    if analyzed_context_module != nil and
         referenced_context_module != nil and
         analyzed_context_module != referenced_context_module do
      raise "You can't reference a #{analyzed_context_module} context within #{referenced_context_module} context"
    else
      :ok
    end
  end

  @spec map_module_to_context_module(module()) :: module() | nil
  defp map_module_to_context_module(module) do
    Enum.find(@contexts, fn context ->
      stringified_context = Atom.to_string(context)
      stringified_module = Atom.to_string(module)

      String.contains?(stringified_module, stringified_context) ||
        stringified_context == stringified_module
    end)
  end
end

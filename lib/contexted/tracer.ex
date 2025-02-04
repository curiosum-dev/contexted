defmodule Contexted.Tracer do
  @moduledoc """
  The `Contexted.Tracer` module provides a set of functions to trace and enforce separation between specific modules, known as "contexts".

  This is useful when you want to ensure that certain modules do not reference each other directly within your application.
  """

  alias Contexted.Utils

  @doc """
  Trace events are emitted during compilation.

  `trace` function verifies if the provided event contains cross-references between two contexts.

  If so, raises an error with an appropriate message.
  """
  @spec trace(tuple(), map()) :: :ok
  def trace({action, _meta, module, _name, _arity}, env)
      when action in [:imported_function, :remote_function, :remote_macro] do
    verify_modules_mismatch(env.module, module, env.file)
  end

  def trace({action, _meta, module, _opts}, env) when action in [:require] do
    verify_modules_mismatch(env.module, module, env.file)
  end

  def trace(_event, _env), do: :ok

  @doc """
  To support automatic docs and specs generation in delegated functions inside contexts, all of the modules have to be compiled first.

  Because of that, we need to run this operation in after compiler callback in two steps:

  1. Remove all contexts beam files.
  2. Generate contexts beam files again.

  This is an opt-in step, so in order to enable it, you will have to set this config:

      config :contexted,
        enable_recompilation: true
  """
  @spec after_compiler(tuple()) :: tuple()
  def after_compiler({status, diagnostics}) do
    file_paths = remove_context_beams_and_return_module_paths()
    beam_folder = get_beam_files_folder_path()

    silence_recompilation_warnings(fn ->
      Kernel.ParallelCompiler.compile_to_path(file_paths, beam_folder)
    end)

    {status, diagnostics}
  end

  @spec get_beam_files_folder_path() :: String.t()
  def get_beam_files_folder_path do
    build_sub_path = Mix.Project.build_path()
    app_sub_path = Utils.get_config_app() |> Atom.to_string()

    Path.join([build_sub_path, "lib", app_sub_path, "ebin"])
  end

  @spec remove_context_beams_and_return_module_paths :: list(String.t())
  defp remove_context_beams_and_return_module_paths do
    Utils.get_config_contexts()
    |> Enum.map(fn module ->
      file_path = module.__info__(:compile)[:source] |> List.to_string()

      :code.which(module) |> List.to_string() |> File.rm()

      file_path
    end)
  end

  @spec verify_modules_mismatch(module(), module(), String.t()) :: :ok
  defp verify_modules_mismatch(analyzed_module, referenced_module, file) do
    if is_file_excluded_from_check?(file) do
      :ok
    else
      analyzed_context_module = map_module_to_context_module(analyzed_module)
      referenced_context_module = map_module_to_context_module(referenced_module)

      if analyzed_context_module != nil and
           referenced_context_module != nil and
           analyzed_context_module != referenced_context_module do
        stringed_referenced_context_module =
          Atom.to_string(referenced_context_module) |> String.replace("Elixir.", "")

        stringed_analyzed_context_module =
          Atom.to_string(analyzed_context_module) |> String.replace("Elixir.", "")

        raise "You can't reference #{stringed_referenced_context_module} context within #{stringed_analyzed_context_module} context."
      else
        :ok
      end
    end
  end

  @spec map_module_to_context_module(module()) :: module() | nil
  defp map_module_to_context_module(module) do
    Utils.get_config_contexts()
    |> Enum.find(fn context ->
      regex = build_regex(context)
      stringified_module = Atom.to_string(module)

      Regex.match?(regex, stringified_module)
    end)
  end

  @spec is_file_excluded_from_check?(String.t()) :: boolean()
  defp is_file_excluded_from_check?(file) do
    Utils.get_config_exclude_paths()
    |> Enum.any?(&String.contains?(file, &1))
  end

  @spec build_regex(module()) :: Regex.t()
  defp build_regex(context) do
    context
    |> Atom.to_string()
    |> then(&~r/\b#{&1}\b/)
  end

  @spec silence_recompilation_warnings((-> any())) :: any()
  defp silence_recompilation_warnings(fun) do
    original_logger_level = Logger.level()
    original_compiler_options = Code.compiler_options()

    Logger.configure(level: :error)
    Code.compiler_options(ignore_module_conflict: true)

    try do
      fun.()
    after
      Logger.configure(level: original_logger_level)
      Code.compiler_options(original_compiler_options)
    end
  end
end

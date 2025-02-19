defmodule Contexted.Utils do
  @moduledoc """
  The `Contexted.Utils` defines utils functions for other modules.
  """

  @doc """
  Checks is `enable_recompilation` option is set.
  """
  @spec recompilation_enabled? :: boolean()
  def recompilation_enabled?,
    do: get_from_config(:enable_recompilation, false) && get_from_config(:app, false)

  @doc """
  Returns `contexts` option value from contexted config or `[]` if it's not set.
  """
  @spec get_config_contexts :: list(module())
  def get_config_contexts, do: get_from_config(:contexts, [])

  @doc """
  Returns `context_options` option value from contexted config or `[]` if it's not set.
  """
  @spec get_config_context_options :: Keyword.t()
  def get_config_context_options, do: get_from_config(:context_options, [])

  @doc """
  Returns `exclude_paths` option value from contexted config or [] if it's not set.
  """
  @spec get_config_exclude_paths :: list(String.t())
  def get_config_exclude_paths, do: get_from_config(:exclude_paths, [])

  @spec get_config_app :: :atom
  def get_config_app, do: get_from_config(:app, nil)

  @spec get_from_config(atom(), any()) :: any()
  defp get_from_config(option_name, default_value) do
    Application.get_env(:contexted, option_name, default_value)
  end
end

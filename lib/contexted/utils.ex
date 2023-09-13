defmodule Contexted.Utils do
  @moduledoc """
  The `Contexted.Utils` defines utils functions for other modules.
  """

  @doc """
  Checks is `enable_recompilation` option is set.
  """
  @spec recompilation_enabled? :: boolean()
  def recompilation_enabled? do
    Application.get_env(:contexted, :enable_recompilation, false)
  end
end

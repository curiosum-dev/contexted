defmodule Context.DelegatorPlus do
  use Spark.Dsl,
    single_extension_kinds: [:delegator],
    default_extensions: [
      delegator: Context.DelegatorDsl
    ]
end

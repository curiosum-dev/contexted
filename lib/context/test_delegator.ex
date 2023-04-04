defmodule Context.TestDelegator do
  use Context.DelegatorPlus

  subcontexts do
    subcontext Context.Test do
      get? true
    end
  end
end

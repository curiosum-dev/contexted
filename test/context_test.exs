defmodule ContextedTest do
  use ExUnit.Case
  doctest Contexted

  describe "cross-context reference checking" do
    test "raises on cross-reference without ignore/1" do
      code = """
      defmodule Foo.Account.UserContext do
        alias Foo.Blog.PostContext
        def hello, do: PostContext.hello()
      end

      defmodule Foo.Blog.PostContext do
        def hello, do: :ok
      end
      """

      Application.put_env(:contexted, :contexts, [Foo.Account, Foo.Blog])
      Code.put_compiler_option(:tracers, [Contexted.Tracer])

      assert_raise RuntimeError,
                   ~r/You can't reference Foo.Blog context within Foo.Account context\./,
                   fn ->
                     Code.compile_string(code, "test/foo_without_ignore.ex")
                   end
    end

    test "does NOT raise when the call is wrapped with Contexted.ignore/1" do
      code = """
      defmodule Bar.Account.UserContext do
        def hello, do: Contexted.ignore(Bar.Blog.PostContext).hello()
      end

      defmodule Bar.Blog.PostContext do
        def hello, do: :ok
      end
      """

      Application.put_env(:contexted, :contexts, [Bar.Account, Bar.Blog])
      Code.put_compiler_option(:tracers, [Contexted.Tracer])

      Code.compile_string(code, "test/bar_with_ignore.ex")
      # credo:disable-for-next-line
      assert :ok = apply(Bar.Account.UserContext, :hello, [])
    end
  end
end

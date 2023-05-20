# Contexted

[![Build Status](https://github.com/curiosum-dev/contexted/workflows/ci/badge.svg)](https://github.com/curiosum-dev/contexted/actions)

[Contexts](https://hexdocs.pm/phoenix/contexts.html) in Elixir & Phoenix are getting complicated over time.
Cross-referencing, big modules and repetitiveness are the most common reasons for this problem.

Contexted arms you with a set of tools to maintain contexts well.


## Features

- `Contexted.Tracer` - trace and enforce definite separation between specific context modules.
- `Contexted.Delegator` - divide the big context module into smaller parts and use delegations to build the final context.
- `Contexted.CRUD` - auto-generate the most common CRUD operations whenever needed.

## Installation

Add the following to your `mix.exs` file:

```elixir
defp deps do
  [
    {:contexted, "~> 0.1.0"}
  ]
end
```

Then run `mix deps.get`.

## Step by step

To describe a sample usage of this library, let's assume that your project has three contexts:
- `Account`
- `Subscription`
- `Blog`

Our goal, as the project grows, is to:
1. Keep contexts separate and don't create any cross-references. For this to work, we'll raise errors during compilation whenever such a cross-reference happens.
2. Divide each context into smaller parts so that it is easier to maintain. In this case, we'll refer to each of these parts as **Subcontext**. It's not a new term added to the Phoenix framework but rather a term proposed to emphasize that it's a subset of Context. For this to work, we'll use delegates.
3. Not repeat ourselves with common business logic operations. For this to work, we'll be using CRUD functions generator, since these are the most common.

### Keep contexts separate

It's very easy to monitor cross-references between context modules with the `contexted` library.

First, add `contexted` as one of the compilers in *mix.exs*:
```elixir
# mix.exs
def project do
  [
    ...
    compilers: [:contexted] ++ Mix.compilers(),
    ...
  ]
end
```

Next, define a list of contexts available in the app inside *config.exs*:
```elixir
# config/config.exs
config :contexted, contexts: [
  # list of contexts goes here, for instance:
  # [App.Account, App.Subscription, App.Blog]
]
```

And that's it. From now on, whenever you will cross-reference one context with another, you will see an error raised during compilation. Here is an example of such an error:

```
== Compilation error in file lib/app/accounts.ex ==
** (RuntimeError) You can't reference App.Blog context within App.Accounts context.
```

### Dividing each context into smaller parts

To divide big Context into smaller Subcontexts, we simply use `delegate_all/1` macro from `Contexted.Delegator` module.

Let's assume that the `Account` context has `User`, `UserToken` and `Admin` resources. Here is how we can split the context module:
```elixir
# Users subcontext

defmodule App.Account.Users do
  def get_user(id) do
    ...
  end
end

# UserTokens subcontext

defmodule App.Account.UserTokens do
  def get_user_token(id) do
    ...
  end
end

# Admins subcontext

defmodule App.Account.Admins do
  def get_admin(id) do
    ...
  end
end

# Account context

defmodule App.Account do
  import Contexted.Delegator
  
  delegate_all App.Account.Users
  delegate_all App.Account.UserTokens
  delegate_all App.Account.Admins
end
```

From now on, you can treat the `Account` context module as the API for the "outside" world.

Instead of calling:
```elixir
App.Account.Users.find_user(1)
```

You will simply do:
```elixir
App.Account.find_user(1)
```

#### Being able to access docs and specs in auto-delegated functions

Both docs and specs are attached as metadata of module once it's compiled and saved as `.beam`. In reference to the example of `App.Account` context, it's possible that `App.Account.Users` will not be saved in `.beam` file before the `delegate_all` macro is executed. Therefore, first, all of the modules have to be compiled, and saved to `.beam` and only then we can create `@doc` and `@spec` of each delegated function.

As a workaround, in `Contexted.Tracer.after_compiler/1` all of the contexts `.beam` files are first deleted and then recompiled. This is an opt-in functionality, as it extends compilation time, and may produce warnings. If you want to enable it, set the following config value:
```elixir
config :contexted,
  enable_recompilation: true
```

You may also want to enable it only for certain environments, like `dev`.

### Don't repeat yourself with CRUD operations

In most web apps CRUD operations are very common. Most of these, have the same pattern. Why not autogenerate them?

Here is how you can generate common CRUD operations for `App.Account.Users`:
```elixir
defmodule App.Account.Users do
  use Contexted.CRUD,
    repo: App.Repo,
    schema: App.Accounts.User
end
```

This will generate the following functions:
```elixir
iex> App.Accounts.Users.__info__(:functions)
[
  change_user: 1,
  change_user: 2,
  create_user: 0,
  create_user: 1,
  create_user!: 0,
  create_user!: 1,
  delete_user: 1,
  delete_user!: 1,
  get_user: 1,
  get_user!: 1,
  list_users: 0,
  update_user: 1,
  update_user: 2,
  update_user!: 1,
  update_user!: 2
]
```

# Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

# License

Distributed under the MIT License. See [LICENSE.md](LICENSE.md) for more information.

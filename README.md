# Contexted Library for Elixir

Contexted is a library for Elixir that adds nice features for working with contexts. It provides tools for tracing and enforcing separation between specific modules, as well as a convenient macro for delegating all functions from one module to another.

## Features

- Trace and enforce separation between specific modules (contexts).
- Delegate all functions from one module to another without the need for individual `defdelegate` statements.

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

## Usage

To describe a sample usage of this library, let's assume that your project has three contexts:
- `Account`
- `Subscription`
- `Blog`

Our goal, as the project grows, is to:
1. Divide each context into smaller parts so that it is easier to maintain. In this case, we'll refer to each of these parts as Subcontext. It's not a new term added to the Phoenix framework but rather something we came up with, to point out that it's a subset of Contexted. For this to work, we'll use delegates.
2. Keep each context as a separate part and do not produce any cross-references. For this to work, we'll raise errors on compile time whenever such a cross-reference happens.

### Dividing each context into smaller parts

To divide big Contexted into smaller Subcontexts, we simply use `defdelegate`. Let's assume that the `Account` context has `User`, `UserToken` and `Admin` resources. Here is how we can deal with it, thanks to `Contexted.Delegator`:
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

From now on, you can treat the `Account` context as the API for the "outside" world.

Instead of calling:
```elixir
App.Account.Users.find_user(1)
```

You will simply do:
```elixir
App.Account.find_user(1)
```

### Keep each context as a separate part

It's very easy to monitor cross-references between context modules with the `context` library.

First, add context as one of the compilers:
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

Next, define a list of contexts available in the app:
```elixir
# config/config.exs
config :contexted, contexts: [
  # list of contexts goes here, for instance: [App.Account, App.Subscription, App.Blog]
]
```

And that's it. From now on, whenever you will cross-reference one context with another, you will see an error raised during compilation.

# License

Distributed under the MIT License. See [LICENSE.md](LICENSE.md) for more information.

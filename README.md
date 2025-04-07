<div align="center">
  <img src="https://github.com/user-attachments/assets/f0352656-397d-4d90-999a-d3adbae1095f">

  <h1>Contexted</h1>
  <p><strong>Tools for clean, maintainable Elixir & Phoenix contexts</strong></p>

  [![Contact Us](https://img.shields.io/badge/Contact%20Us-%23F36D2E?style=for-the-badge&logo=maildotru&logoColor=white&labelColor=F36D2E)](https://curiosum.com/contact)
  [![Visit Curiosum](https://img.shields.io/badge/Visit%20Curiosum-%236819E6?style=for-the-badge&logo=elixir&logoColor=white&labelColor=6819E6)](https://curiosum.com/services/elixir-software-development)
  [![License: MIT](https://img.shields.io/badge/License-MIT-1D0642?style=for-the-badge&logo=open-source-initiative&logoColor=white&labelColor=1D0642)](https://github.com/curiosum-dev/contexted/blob/main/LICENSE)
</div>


<br/>

## 📦 Short overview

[Contexts](https://hexdocs.pm/phoenix/contexts.html) in Elixir & Phoenix are getting complicated over time.
Cross-referencing, big modules and repetitiveness are the most common reasons for this problem.

Contexted arms you with a set of tools to maintain contexts well.

<div>
  <a href="https://github.com/curiosum-dev/contexted/actions/workflows/ci.yml">
    <img alt="CI Status" src="https://github.com/curiosum-dev/contexted/actions/workflows/ci.yml/badge.svg">
  </a>
  <a href="https://hex.pm/packages/contexted">
    <img alt="Hex Version" src="https://img.shields.io/hexpm/v/contexted.svg">
  </a>
  <a href="https://hexdocs.pm/contexted">
    <img alt="Hex Docs" src="http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat">
  </a>
</div>

<br/>

---

_Note: Official documentation for contexted library is [available on hexdocs][hexdoc]._

[hexdoc]: https://hexdocs.pm/contexted

---

<br/>

## 📚 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Step by step overview](#-step-by-step-overview)
  - [Keep contexts separate](#keep-contexts-separate)
    - [Exclude files and folders from check context cross-references](#exclude-files-and-folders-from-cross-references-context-check)
  - [Dividing each context into smaller parts](#dividing-each-context-into-smaller-parts)
    - [Being able to access docs and specs in auto-delegated functions](#being-able-to-access-docs-and-specs-in-auto-delegated-functions)
  - [Don't repeat yourself with CRUD operations](#dont-repeat-yourself-with-crud-operations)
- [Contributing](#-contributing)
- [License](#-license)

<br/>

## ✨ Features

- `Contexted.Tracer` - trace and enforce definite separation between specific context modules.
- `Contexted.Delegator` - divide the big context module into smaller parts and use delegations to build the final context.
- `Contexted.CRUD` - auto-generate the most common CRUD operations whenever needed.

<br/>

## 📥 Installation

Add the following to your `mix.exs` file:

```elixir
defp deps do
  [
    {:contexted, "~> 0.3.4"}
  ]
end
```

Then run `mix deps.get`.

<br/>

## 🧭 Step by step overview

To describe a sample usage of this library, let's assume that your project has three contexts:

- `Account`
- `Subscription`
- `Blog`

Our goal, as the project grows, is to:

1. Keep contexts separate and not create any cross-references. For this to work, we'll raise errors during compilation whenever such a cross-reference happens.
2. Divide each context into smaller parts so that it is easier to maintain. In this case, we'll refer to each of these parts as **Subcontext**. It's not a new term added to the Phoenix framework but rather a term proposed to emphasize that it's a subset of Context. For this to work, we'll use delegates.
3. Not repeat ourselves with common business logic operations. For this to work, we'll be using CRUD functions generator, since these are the most common.

<br/>

### Keep contexts separate

It's very easy to monitor cross-references between context modules with the `contexted` library.

First, add `contexted` as one of the compilers in _mix.exs_:

```elixir
def project do
  [
    ...
    compilers: [:contexted] ++ Mix.compilers(),
    ...
  ]
end
```

Next, define a list of contexts available in the app inside config file:

```elixir
config :contexted, contexts: [
  # list of context modules goes here, for instance:
  # [App.Account, App.Subscription, App.Blog]
]
```

And that's it. From now on, whenever you will cross-reference one context with another, you will see an error raised during compilation. Here is an example of such an error:

```
== Compilation error in file lib/app/accounts.ex ==
** (RuntimeError) You can't reference App.Blog context within App.Accounts context.
```

Read more about `Contexted.Tracer` and its options in [docs](https://hexdocs.pm/contexted/Contexted.Tracer.html).

<br/>

#### Exclude files and folders from cross-references context check

In special cases, you may need to exclude certain folders or files from cross-reference checks due to project structure or naming conventions. To do this, add a list of exclusions in config `exclude_paths` option:

```elixir
config :contexted,
  exclude_paths: ["app/test"]
```

<br/>

### Dividing each context into smaller parts

To divide big Context into smaller Subcontexts, we can use `delegate_all/1` macro from `Contexted.Delegator` module.

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

<br/>

#### Being able to access docs and specs in auto-delegated functions

Both docs and specs are attached as metadata of module once it's compiled and saved as `.beam`. In reference to the example of `App.Account` context, it's possible that `App.Account.Users` will not be saved in `.beam` file before the `delegate_all` macro is executed. Therefore, first, all of the modules have to be compiled, and saved to `.beam` and only then we can create `@doc` and `@spec` of each delegated function.

As a workaround, in `Contexted.Tracer.after_compiler/1` all of the contexts `.beam` files are first deleted and then recompiled. This is an opt-in functionality, as it extends compilation time. If you want to enable it, set the following config values:

```elixir
config :contexted,
  app: :your_app_name, # replace 'your_app_name' with your real app name
  enable_recompilation: true
```

You may also want to enable it only for certain environments, like `dev`.

*Please also note that when this functionality is enabled, during the recompilation process, warnings are temporarily silenced to avoid logging conflict warnings. It will still log warnings as intended, during the first compilation, therefore it won't have any affect on normal compilation flow.*

Read more about `Contexted.Delegator` and its options in [docs](https://hexdocs.pm/contexted/Contexted.Delegator.html).

<br/>

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


Read more about `Contexted.CRUD` and its options in [docs](https://hexdocs.pm/contexted/Contexted.CRUD.html).

<br/>

# 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

<br/>

# 📄 License

[Curiosum](https://curiosum.com)

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.

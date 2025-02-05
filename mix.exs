defmodule Contexted.MixProject do
  use Mix.Project

  def project do
    [
      app: :contexted,
      description:
        "Contexted is an Elixir library designed to streamline the management of complex Phoenix contexts in your projects, offering tools for module separation, subcontext creation, and auto-generating CRUD operations for improved code maintainability.",
      version: "0.3.3",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:versioce, "~> 2.0.0", only: :dev, runtime: false},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0", optional: true},
      {:postgrex, ">= 0.0.0", optional: true, only: [:dev, :test]}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Curiosum"],
      links: %{"GitHub" => "https://github.com/curiosum-dev/contexted"},
      files: ~w(lib mix.exs README.md LICENSE)
    ]
  end
end

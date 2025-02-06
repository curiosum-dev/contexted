defmodule Contexted.MixProject do
  use Mix.Project

  @version "0.3.3"
  @source_url "https://github.com/curiosum-dev/contexted"

  def project do
    [
      app: :contexted,
      description:
        "Contexted is an Elixir library designed to streamline the management of complex Phoenix contexts in your projects, offering tools for module separation, subcontext creation, and auto-generating CRUD operations for improved code maintainability.",
      version: "0.3.3",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
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
      {:versioce, "~> 2.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Curiosum"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md"]
      # groups_for_extras: [
      #   "Getting Started": ~r/README\.md/
      # ]
    ]
  end
end

defmodule Bb.MixProject do
  use Mix.Project

  def project do
    [
      app: :bb,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Bb.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.1"},
      {:gen_stage, "~> 1.0"},
      {:broadway, "~> 0.6.0-rc.0"},
      {:poolboy, "~> 1.5"},
      {:telemetry, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end

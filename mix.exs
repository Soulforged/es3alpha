defmodule Es3Alpha.Mixfile do
  use Mix.Project

  def project do
    [
      app: :es3alpha,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      deps: deps(),
      dialyzer: [plt_add_apps: [:mnesia]]
    ]
  end

  def application, do: application(Mix.env)
  def application(:test), do: [mod: {Es3Alpha.Support.App, []}, extra_applications: [:logger, :cowboy]]
  def application(_), do: [mod: {Es3Alpha, []}, extra_applications: [:logger, :cowboy]]

  defp deps do
    [
      {:cowboy, "~> 2.1"},
      {:poison, "~> 3.1.0"},
      {:httpoison, "~> 0.13.0", only: [:test]},
      {:dialyxir, "~> 0.5.1", only: [:dev], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end

defmodule Es3Alpha.Mixfile do
  use Mix.Project

  def project do
    [
      app: :es3alpha,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [mod: {Es3Alpha, []}, extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1.0"}
    ]
  end
end

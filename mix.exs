defmodule RobotRaceWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :robot_race_web,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: [
        formatters: ["html"],
        output: "priv/static/doc"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {RobotRaceWeb.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, github: "phoenixframework/phoenix", ref: "e8a12ce", override: true},
      {:phoenix_live_view,
       github: "phoenixframework/phoenix_live_view", ref: "e1508d4", override: true},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_pubsub, "~> 2.0"},
      {:esbuild, "~> 0.1", runtime: Mix.env() == :dev},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:ecto, "~> 3.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:uuid, "~> 1.1"},
      {:optimal, "~> 0.3.6"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:credo_contrib, "~> 0.2.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end
end

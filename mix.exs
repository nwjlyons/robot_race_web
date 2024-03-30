defmodule RobotRaceWeb.MixProject do
  use Mix.Project

  @source_url "https://github.com/nwjlyons/robot_race_web"

  def project do
    [
      app: :robot_race_web,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: docs()
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
      {:phoenix, "~> 1.7"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_view, "~> 0.20.1"},
      {:phoenix_live_reload, "~> 1.5.3", only: :dev},
      {:phoenix_pubsub, "~> 2.1"},
      {:esbuild, "~> 0.1", runtime: Mix.env() == :dev},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.6"},
      {:ecto, "~> 3.11"},
      {:phoenix_ecto, "~> 4.4"},
      {:ex_doc, "~> 0.24", runtime: false},
      {:nanoid, "~> 2.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:credo_contrib, "~> 0.2.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:typed_struct, "~> 0.3.0", runtime: false}
    ]
  end

  defp docs() do
    [
      api_reference: false,
      extras: [],
      source_url: @source_url,
      main: "RobotRace.Game",
      formatters: ["html"],
      output: "priv/static/doc",
      groups_for_modules: groups_for_modules()
    ]
  end

  defp groups_for_modules() do
    [
      Structs: [
        RobotRace.Game,
        RobotRace.GameConfig,
        RobotRace.Robot,
        RobotRace.Id,
        RobotRace.GameId,
        RobotRace.RobotId
      ],
      Views: [
        RobotRaceWeb.GameController,
        RobotRaceWeb.GameLive,
        RobotRaceWeb.LobbyLive
      ],
      Forms: [
        RobotRaceWeb.JoinGameForm
      ],
      Components: [
        RobotRaceWeb.Components
      ],
      GenServers: [
        RobotRaceWeb.GameServer
      ]
    ]
  end

  defp aliases do
    [
      "assets.deploy": ["esbuild default --minify", "phx.digest"],
      "deps.sync": ["deps.get", "deps.clean --unlock --unused"]
    ]
  end
end

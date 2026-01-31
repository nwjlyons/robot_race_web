defmodule RobotRaceWeb.MixProject do
  use Mix.Project

  @source_url "https://github.com/nwjlyons/robot_race_web"

  def project do
    [
      app: :robot_race_web,
      version: "0.1.0",
      elixir: "~> 1.18",
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
      {:phoenix, "~> 1.7.14"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_view, "~> 1.0.0"},
      {:phoenix_live_reload, "~> 1.5.3", only: :dev},
      {:phoenix_pubsub, "~> 2.1"},
      {:esbuild, "~> 0.8.2", runtime: Mix.env() == :dev},
      {:bandit, "~> 1.6"},
      {:ecto, "~> 3.12.4"},
      {:phoenix_ecto, "~> 4.4"},
      {:ex_doc, "~> 0.37", runtime: false},
      {:nanoid, "~> 2.1"},
      {:phoenix_html_helpers, "~> 1.0"}
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
      "deps.sync": ["deps.get", "deps.clean --unlock --unused"],
      lint: ["format", "compile"]
    ]
  end
end

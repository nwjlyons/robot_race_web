import Config

config :robot_race_web, RobotRaceWeb.Endpoint,
  code_reloader: true,
  debug_errors: true,
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ],
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
      ~r{lib/robot_race_web/views/.*(ex)$},
      ~r{lib/robot_race_web/live/.*(ex|heex)$},
      ~r{lib/robot_race_web/templates/.*(eex)$}
    ]
  ]

config :phoenix_live_view, debug_heex_annotations: true

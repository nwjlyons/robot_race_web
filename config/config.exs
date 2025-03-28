import Config

config :robot_race_web, RobotRaceWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  http: [port: 4000],
  pubsub_server: RobotRaceWeb.PubSub,
  secret_key_base: "gn4l7o7fa1MsV0wAbE6wVzb2kX6/TQKmnn6OA7TnHnbn3pxmYi0pppJNfXUGiXts",
  live_view: [signing_salt: "V/Dpj928QGehEzOFm44bIa0nxqtUUU8PY0+QP3O8CdtcurRw3C27Scy7GCvH6Xdf"]

config :phoenix, :json_library, JSON

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :esbuild,
  version: "0.12.15",
  default: [
    args: ~w(js/app.ts --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

import_config "#{config_env()}.exs"

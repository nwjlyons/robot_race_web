import Config

config :robot_race_web, RobotRaceWeb.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json"

import Config

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :robot_race_web, RobotRaceWeb.Endpoint,
    server: true,
    url: [scheme: "https", host: System.get_env("HOST"), port: 443],
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      # IMPORTANT: support IPv6 addresses
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base
end

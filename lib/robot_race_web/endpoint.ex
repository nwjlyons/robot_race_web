defmodule RobotRaceWeb.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :robot_race_web

  @session_options [
    store: :cookie,
    # Two weeks
    max_age: 60 * 60 * 24 * 14,
    key: "_robot_race",
    signing_salt: "3WZQ85Tu",
    encryption_salt: "gvkjLOmjZOx0esLoT5nGmzps8p0YfyFowXgpWQ2oGOcjGUNOrStMnV/jnW0bfqdn"
  ]

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options], timeout: 45_000]
  )

  plug(Plug.Static,
    at: "/robo/doc",
    from: {:robot_race_web, "priv/static/doc"},
  )

  plug(Plug.Static,
    at: "/",
    from: :robot_race_web,
    gzip: true,
    only: ~w(assets fonts images favicon.ico robots.txt)
  )

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug(Plug.RequestId)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(RobotRaceWeb.Router)
end

defmodule RobotRaceWeb.Router do
  @moduledoc false

  use Phoenix.Router, helpers: false

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {RobotRaceWeb.LayoutView, "root.html"}
  end

  scope "/" do
    pipe_through :browser

    live "/_stats", RobotRaceWeb.StatsLive, :stats, container: {:div, class: "h-full flex"}
    live "/:id/join", RobotRaceWeb.LobbyLive, :join, container: {:div, class: "h-full flex"}
    get "/:id", RobotRaceWeb.GameController, :show
    post "/:id", RobotRaceWeb.GameController, :join
    post "/", RobotRaceWeb.GameController, :create
    live "/", RobotRaceWeb.LobbyLive, :create, container: {:div, class: "h-full flex"}
  end
end

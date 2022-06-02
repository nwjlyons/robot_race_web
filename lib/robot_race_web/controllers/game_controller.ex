defmodule RobotRaceWeb.GameController do
  use RobotRaceWeb, :controller

  import Phoenix.LiveView.Controller

  alias RobotRace.Game
  alias RobotRace.Robot
  alias RobotRaceWeb.GameServer

  @cookie_max_age 60 * 60
  @cookie_name "robot_id"

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(%Plug.Conn{} = conn, %{"join_game_form" => %{"name" => name}}) do
    robot = Robot.new(%{name: name})
    game = Game.new()

    DynamicSupervisor.start_child(
      RobotRaceWeb.DynamicSupervisor,
      {RobotRaceWeb.GameServer, %{game: game, admin_id: robot.id}}
    )

    %GameServer{} = GameServer.join(game.id, robot)

    game_path = Routes.game_path(conn, :show, game.id)

    conn
    |> put_resp_cookie(@cookie_name, robot.id,
      path: game_path,
      sign: true,
      max_age: @cookie_max_age
    )
    |> redirect(to: game_path)
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(%Plug.Conn{} = conn, %{"id" => id}) do
    if GameServer.exists?(id) do
      case fetch_cookies(conn, signed: [@cookie_name]) do
        %Plug.Conn{cookies: %{@cookie_name => robot_id}} = conn ->
          live_render(conn, RobotRaceWeb.GameLive,
            session: %{"game_id" => id, "robot_id" => robot_id},
            container: {:div, class: "h-full"}
          )

        %Plug.Conn{} = conn ->
          redirect(conn, to: Routes.lobby_path(conn, :join, id))
      end
    else
      conn
      |> put_flash(:info, "game not found")
      |> redirect(to: Routes.lobby_path(conn, :create))
    end
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(%Plug.Conn{} = conn, %{"id" => game_id, "join_game_form" => %{"name" => name}}) do
    %Robot{} = robot = Robot.new(%{name: name})
    %GameServer{} = GameServer.join(game_id, robot)

    game_path = Routes.game_path(conn, :show, game_id)

    conn
    |> put_resp_cookie(@cookie_name, robot.id,
      path: game_path,
      sign: true,
      max_age: @cookie_max_age
    )
    |> redirect(to: game_path)
  end
end

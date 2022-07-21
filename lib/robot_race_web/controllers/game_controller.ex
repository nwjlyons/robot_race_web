defmodule RobotRaceWeb.GameController do
  use RobotRaceWeb, :controller

  import Phoenix.LiveView.Controller, only: [live_render: 3]

  alias RobotRace.Game
  alias RobotRace.Robot
  alias RobotRaceWeb.GameServer

  @cookie_max_age 60 * 60
  @cookie_name "robot_id"

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(%Plug.Conn{} = conn, %{"join_game_form" => %{"name" => name}}) do
    {game, robot} = create_game(name)
    redirect_to_game(conn, game, robot)
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

  @spec join(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def join(%Plug.Conn{} = conn, %{"id" => game_id, "join_game_form" => %{"name" => name}}) do
    %Robot{} = robot = Robot.new(name, :guest)

    case GameServer.join(game_id, robot) do
      {:ok, %Game{} = game} ->
        redirect_to_game(conn, game, robot)

      {:error, :game_in_progress} ->
        error("game in progress")

      {:error, :max_robots} ->
        error("game full")
    end
  end

  @spec create_game(String.t()) :: {Game.t(), Robot.t()}
  defp create_game(name) do
    robot = Robot.new(name, :admin)
    game = Game.new()
    {:ok, _pid} = GameServer.new(game)
    {:ok, %Game{}} = GameServer.join(game.id, robot)

    {game, robot}
  end

  @spec redirect_to_game(Plug.Conn.t(), Game.t(), Robot.t()) :: Plug.Conn.t()
  defp redirect_to_game(%Plug.Conn{} = conn, %Game{} = game, %Robot{} = robot) do
    game_path = Routes.game_path(conn, :show, game.id)

    conn
    |> put_resp_cookie(@cookie_name, robot.id,
      path: game_path,
      sign: true,
      max_age: @cookie_max_age
    )
    |> redirect(to: game_path)
  end

  @spec error(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  defp error(%Plug.Conn{} = conn, message \\ "Error") when is_binary(message) do
    conn
    |> put_view(RobotRaceWeb.ErrorView)
    |> put_status(:unprocessable_entity)
    |> render("error.html", error: message)
  end
end

defmodule RobotRaceWeb.GameController do
  @moduledoc """
  GameController wraps GameLive. It exists mainly to read cookies, as LiveViews can't do this.
  """

  use RobotRaceWeb, :controller

  import Phoenix.LiveView.Controller, only: [live_render: 3]

  alias RobotRace.Game
  alias RobotRace.Robot
  alias RobotRaceWeb.GameServer

  @cookie_max_age 60 * 60
  @cookie_name "robot_id"

  @doc """
  Endpoint to create game.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(%Plug.Conn{} = conn, %{"join_game_form" => %{"name" => name}}) do
    {game, robot} = create_game(name)
    conn = assign(conn, :game_id, game.id)
    redirect_to_game(conn, game, robot)
  end

  @doc """
  Endpoint to play game.
  """
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
          redirect(conn, to: ~p"/#{id}/join")
      end
    else
      conn
      |> put_flash(:info, "game not found")
      |> redirect(to: ~p"/")
    end
  end

  @doc """
  Endpoint to join game.
  """
  @spec join(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def join(%Plug.Conn{} = conn, %{"id" => game_id, "join_game_form" => %{"name" => name}}) do
    %Robot{} = robot = Robot.new(name, :guest)

    case GameServer.join(game_id, robot) do
      {:ok, %Game{} = game} ->
        redirect_to_game(conn, game, robot)

      {:error, :game_in_progress} ->
        error(conn, "game in progress")

      {:error, :game_full} ->
        error(conn, "game full")
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
    game_path = ~p"/#{game.id}"

    conn
    |> put_resp_cookie(@cookie_name, robot.id,
      path: game_path,
      sign: true,
      max_age: @cookie_max_age
    )
    |> redirect(to: game_path)
  end

  @spec error(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  defp error(%Plug.Conn{} = conn, message) when is_binary(message) do
    conn
    |> put_view(RobotRaceWeb.ErrorView)
    |> put_status(:unprocessable_entity)
    |> render("error.html", error: message)
  end
end

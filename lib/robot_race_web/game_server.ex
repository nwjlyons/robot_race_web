defmodule RobotRaceWeb.GameServer do
  @moduledoc """
  GameServer.
  """

  import RobotRace.GameId
  import RobotRace.RobotId

  alias RobotRace.Game
  alias RobotRace.GameId
  alias RobotRace.Robot
  alias RobotRace.RobotId

  @doc """
  Create new game server process.
  """
  @spec new(Game.t()) :: DynamicSupervisor.on_start_child()
  def new(%Game{} = game) do
    DynamicSupervisor.start_child(RobotRaceWeb.DynamicSupervisor, {__MODULE__, game})
  end

  @spec child_spec(Game.t()) :: Supervisor.child_spec()
  def child_spec(%Game{} = game) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [game]},
      restart: :transient,
      type: :worker
    }
  end

  @spec start_link(Game.t()) :: GenServer.on_start()
  def start_link(%Game{} = game), do: :robot_race_game_server.start_link(game)

  @doc """
  Does game exist.
  """
  @spec exists?(GameId.t()) :: boolean()
  def exists?(game_id() = game_id), do: :robot_race_game_server.exists(game_id)
  def exists?(_game_id), do: false

  @doc """
  Get game.
  """
  @spec get(GameId.t()) :: Game.t()
  def get(game_id() = game_id), do: :robot_race_game_server.get(game_id)

  @doc """
  Join game.
  """
  @spec join(GameId.t(), Robot.t()) :: {:ok, Game.t()} | {:error, Game.join_error()}
  def join(game_id() = game_id, %Robot{} = robot),
    do: :robot_race_game_server.join(game_id, robot)

  @doc """
  Countdown to start.
  """
  @spec countdown(GameId.t()) :: Game.t()
  def countdown(game_id() = game_id), do: :robot_race_game_server.countdown(game_id)

  @doc """
  Score point.
  """
  @spec score_point(GameId.t(), RobotId.t()) :: Game.t()
  def score_point(game_id() = game_id, robot_id() = robot_id),
    do: :robot_race_game_server.score_point(game_id, robot_id)

  @doc """
  Reset game, ready to play again.
  """
  @spec play_again(GameId.t()) :: Game.t()
  def play_again(game_id() = game_id), do: :robot_race_game_server.play_again(game_id)

  @spec subscribe(Game.t()) :: :ok | {:error, term()}
  def subscribe(%Game{} = game), do: :robot_race_game_server.subscribe(game)
end

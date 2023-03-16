defmodule RobotRace.Game do
  @moduledoc """
  This module defines the Game struct and its associated functions, which are used to manage
  a robot race game, including the game state, participating robots, and their scores.
  """
  import RobotRace.RobotId

  alias RobotRace.GameConfig
  alias RobotRace.GameId
  alias RobotRace.Robot
  alias RobotRace.RobotId

  @enforce_keys [:id, :winning_score, :num_robots, :countdown, :config]
  defstruct [
    :id,
    :winning_score,
    :num_robots,
    :countdown,
    :config,
    robots: %{},
    robots_order: [],
    state: :setup
  ]

  @type t() :: %__MODULE__{
          id: GameId.t(),
          winning_score: pos_integer(),
          num_robots: Range.t(pos_integer(), pos_integer()),
          countdown: pos_integer(),
          config: GameConfig.t(),
          robots: %{RobotId.t() => Robot.t()},
          robots_order: list(RobotId.t()),
          state: state()
        }
  @type state() :: :setup | :counting_down | :playing | :finished

  @type join_game_error() :: :game_in_progress | :max_robots

  @doc """
  Create a new game instance with the specified configuration or a default configuration.

  Returns a new game struct.
  """
  @spec new(GameConfig.t()) :: t()
  def new(%GameConfig{} = config \\ %GameConfig{}) do
    %__MODULE__{
      id: GameId.new(),
      winning_score: config.winning_score,
      num_robots: config.num_robots,
      countdown: config.countdown,
      config: config
    }
  end

  @doc """
  Join a game with the specified robot.

  Returns an updated game struct if the robot is able to join, or an error if the game is
  in progress or the maximum number of robots has been reached.
  """
  @spec join(t(), Robot.t()) :: {:ok, t()} | {:error, join_game_error()}
  def join(%__MODULE__{state: state}, %Robot{})
      when state in [:counting_down, :playing, :finished] do
    {:error, :game_in_progress}
  end

  def join(%__MODULE__{robots: %{} = robots, num_robots: %Range{last: max_robots}}, %Robot{})
      when map_size(robots) >= max_robots do
    {:error, :max_robots}
  end

  def join(%__MODULE__{} = game, %Robot{} = robot) do
    {:ok,
     %__MODULE__{
       game
       | robots: Map.put(game.robots, robot.id, robot),
         robots_order: game.robots_order ++ [robot.id]
     }}
  end

  @doc """
  Score a point for the specified robot.

  Returns an updated game struct with the robot's score incremented. If the robot's score
  reaches the winning score, the game state is set to `:finished`.
  """
  @spec score_point(t(), RobotId.t()) :: t()
  def score_point(%__MODULE__{state: :playing} = game, robot_id() = robot_id) do
    robot = Map.fetch!(game.robots, robot_id)
    robot = %Robot{robot | score: robot.score + 1}
    game = %__MODULE__{game | robots: Map.replace!(game.robots, robot.id, robot)}

    if robot.score >= game.winning_score do
      %__MODULE__{game | state: :finished}
    else
      game
    end
  end

  def score_point(%__MODULE__{} = game, robot_id() = _robot_id), do: game

  @doc """
  List all robots in the game in the order they joined.

  Returns a list of robot structs.
  """
  @spec robots(t()) :: list(Robot.t())
  def robots(%__MODULE__{} = game) do
    Enum.map(game.robots_order, &Map.fetch!(game.robots, &1))
  end

  @doc """
  Check if a robot with the specified ID is an admin.

  Returns true if the robot is an admin, false otherwise.
  """
  @spec admin?(t(), RobotId.t()) :: boolean()
  def admin?(%__MODULE__{} = game, robot_id() = robot_id) do
    robot = Map.fetch!(game.robots, robot_id)
    robot.role == :admin
  end

  @doc """
  Set the game state to `:playing`, allowing robots to score points.

  Returns an updated game struct.
  """
  @spec play(t()) :: t()
  def play(%__MODULE__{} = game), do: %__MODULE__{game | state: :playing}

  @doc """
  Countdown to start.
  """
  @spec countdown(t()) :: t()
  def countdown(%__MODULE__{state: :setup} = game) do
    %__MODULE__{game | state: :counting_down}
  end

  def countdown(%__MODULE__{countdown: countdown} = game) when countdown > 0 do
    %__MODULE__{game | state: :counting_down, countdown: countdown - 1}
  end

  def countdown(%__MODULE__{countdown: 0} = game) do
    %__MODULE__{game | state: :playing}
  end

  @doc """
  List robots by score in descending order.
  """
  @spec score_board(t()) :: list(Robot.t())
  def score_board(%__MODULE__{robots: robots}) do
    robots
    |> Map.values()
    |> Enum.sort_by(fn %Robot{score: score} -> score end, :desc)
  end

  @doc """
  Return winning robot.
  """
  @spec winner(t()) :: Robot.t()
  def winner(%__MODULE__{} = game) do
    game
    |> score_board()
    |> hd()
  end

  @doc """
  Play again.
  """
  @spec play_again(t()) :: t()
  def play_again(%__MODULE__{} = game) do
    %__MODULE__{
      game
      | winning_score: game.config.winning_score,
        num_robots: game.config.num_robots,
        countdown: game.config.countdown,
        robots: reset_robot_scores(game.robots),
        state: :setup
    }
  end

  defp reset_robot_scores(%{} = robots) do
    robots
    |> Enum.map(fn {robot_id, %Robot{} = robot} ->
      {robot_id, %Robot{robot | score: 0}}
    end)
    |> Enum.into(%{})
  end
end

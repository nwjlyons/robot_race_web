defmodule RobotRace.Game do
  @moduledoc """
  Game struct and functions.
  """
  import RobotRace.RobotId

  alias RobotRace.GameConfig
  alias RobotRace.GameId
  alias RobotRace.Robot
  alias RobotRace.RobotId

  @enforce_keys [:id, :winning_score, :num_robots, :countdown, :config]
  defstruct id: nil,
            winning_score: nil,
            num_robots: nil,
            countdown: nil,
            config: nil,
            robots: [],
            state: :setup,
            previous_wins: %{}

  @type t() :: %__MODULE__{
          id: GameId.t(),
          winning_score: pos_integer(),
          num_robots: Range.t(pos_integer(), pos_integer()),
          countdown: pos_integer(),
          config: GameConfig.t(),
          robots: [Robot.t()],
          state: state(),
          previous_wins: %{RobotId.t() => non_neg_integer()}
        }

  @type state() :: :setup | :counting_down | :playing | :finished

  @doc """
  New game.
  """
  @spec new(GameConfig.t()) :: t()
  def new(%GameConfig{} = config), do: :robot_race_game.new(config)
  def new(), do: :robot_race_game.new()

  @type join_error() :: :game_in_progress | :game_full

  @doc """
  Join game.
  """
  @spec join(t(), Robot.t()) :: {:ok, t()} | {:error, join_error()}
  def join(%__MODULE__{} = game, %Robot{} = robot), do: :robot_race_game.join(game, robot)

  @doc """
  Score a point.
  """
  @spec score_point(t(), RobotId.t()) :: t()
  def score_point(%__MODULE__{} = game, robot_id() = robot_id),
    do: :robot_race_game.score_point(game, robot_id)

  def score_point(%__MODULE__{} = game, _), do: game

  @doc """
  List robots by insertion order.
  """
  @spec robots(t()) :: list(Robot.t())
  def robots(%__MODULE__{} = game), do: :robot_race_game.robots(game)

  @doc """
  Is Robot an admin.
  """
  @spec admin?(t(), RobotId.t()) :: boolean()
  def admin?(%__MODULE__{} = game, robot_id() = robot_id),
    do: :robot_race_game.admin(game, robot_id)

  @doc """
  Play game.
  """
  @spec play(t()) :: t()
  def play(%__MODULE__{} = game), do: :robot_race_game.play(game)

  @doc """
  Countdown to start.
  """
  @spec countdown(t()) :: t()
  def countdown(%__MODULE__{} = game), do: :robot_race_game.countdown(game)

  @doc """
  List robots by score in descending order.
  """
  @spec score_board(t()) :: list(Robot.t())
  def score_board(%__MODULE__{} = game), do: :robot_race_game.score_board(game)

  @doc """
  Return winning robot.
  """
  @spec winner!(t()) :: Robot.t()
  def winner!(%__MODULE__{} = game), do: :robot_race_game.winner(game)

  @doc """
  Play again.
  """
  @spec play_again(t()) :: t()
  def play_again(%__MODULE__{} = game), do: :robot_race_game.play_again(game)

  @doc """
  Leaderboard

  Robots with scores sorted in descending order.
  """
  @spec leaderboard(t()) :: list({Robot.t(), non_neg_integer()})
  def leaderboard(%__MODULE__{} = game), do: :robot_race_game.leaderboard(game)
end

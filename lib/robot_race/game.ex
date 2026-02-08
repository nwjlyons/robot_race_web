defmodule RobotRace.Game do
  @moduledoc """
  Game struct and functions.
  """

  alias RobotRace.GameConfig
  alias RobotRace.GameId
  alias RobotRace.PythonDomain
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
  def new(%GameConfig{} = config \\ %GameConfig{}) do
    :new_game
    |> PythonDomain.call(%{"config" => GameConfig.to_python(config)})
    |> from_python()
  end

  @type join_error() :: :game_in_progress | :game_full

  @doc """
  Join game.
  """
  @spec join(t(), Robot.t()) :: {:ok, t()} | {:error, join_error()}
  def join(%__MODULE__{} = game, %Robot{} = robot) do
    case PythonDomain.call(:join, %{"game" => to_python(game), "robot" => Robot.to_python(robot)}) do
      %{"status" => "ok", "game" => updated_game} ->
        {:ok, from_python(updated_game)}

      %{"status" => "error", "error" => error} ->
        {:error, join_error_from_python(error)}
    end
  end

  @doc """
  Score a point.
  """
  @spec score_point(t(), RobotId.t()) :: t()
  def score_point(%__MODULE__{} = game, robot_id) when is_binary(robot_id) do
    :score_point
    |> PythonDomain.call(%{"game" => to_python(game), "robot_id" => robot_id})
    |> from_python()
  end

  def score_point(%__MODULE__{} = game, _robot_id), do: game

  @doc """
  List robots by insertion order.
  """
  @spec robots(t()) :: list(Robot.t())
  def robots(%__MODULE__{} = game) do
    :robots
    |> PythonDomain.call(%{"game" => to_python(game)})
    |> Enum.map(&Robot.from_python/1)
  end

  @doc """
  Is Robot an admin.
  """
  @spec admin?(t(), RobotId.t()) :: boolean()
  def admin?(%__MODULE__{} = game, robot_id) when is_binary(robot_id) do
    case PythonDomain.call(:admin, %{"game" => to_python(game), "robot_id" => robot_id}) do
      true -> true
      false -> false
      nil -> raise KeyError, key: robot_id, term: game.robots
    end
  end

  @doc """
  Play game.
  """
  @spec play(t()) :: t()
  def play(%__MODULE__{} = game) do
    :play
    |> PythonDomain.call(%{"game" => to_python(game)})
    |> from_python()
  end

  @doc """
  Countdown to start.
  """
  @spec countdown(t()) :: t()
  def countdown(%__MODULE__{} = game) do
    :countdown
    |> PythonDomain.call(%{"game" => to_python(game)})
    |> from_python()
  end

  @doc """
  List robots by score in descending order.
  """
  @spec score_board(t()) :: list(Robot.t())
  def score_board(%__MODULE__{} = game) do
    :score_board
    |> PythonDomain.call(%{"game" => to_python(game)})
    |> Enum.map(&Robot.from_python/1)
  end

  @doc """
  Return winning robot.
  """
  @spec winner!(t()) :: Robot.t()
  def winner!(%__MODULE__{} = game) do
    game
    |> score_board()
    |> hd()
  end

  @doc """
  Play again.
  """
  @spec play_again(t()) :: t()
  def play_again(%__MODULE__{} = game) do
    :play_again
    |> PythonDomain.call(%{"game" => to_python(game)})
    |> from_python()
  end

  @doc """
  Leaderboard

  Robots with scores sorted in descending order.
  """
  @spec leaderboard(t()) :: list({Robot.t(), non_neg_integer()})
  def leaderboard(%__MODULE__{} = game) do
    :leaderboard
    |> PythonDomain.call(%{"game" => to_python(game)})
    |> Enum.map(fn {robot, score} -> {Robot.from_python(robot), score} end)
  end

  @spec to_python(t()) :: map()
  def to_python(%__MODULE__{} = game) do
    %{
      "id" => game.id,
      "winning_score" => game.winning_score,
      "num_robots" => range_to_python(game.num_robots),
      "countdown" => game.countdown,
      "config" => GameConfig.to_python(game.config),
      "robots" => Enum.map(game.robots, &Robot.to_python/1),
      "state" => state_to_python(game.state),
      "previous_wins" => game.previous_wins
    }
  end

  @spec from_python(map()) :: t()
  def from_python(%{
        "id" => id,
        "winning_score" => winning_score,
        "num_robots" => num_robots,
        "countdown" => countdown,
        "config" => config,
        "robots" => robots,
        "state" => state,
        "previous_wins" => previous_wins
      }) do
    %__MODULE__{
      id: id,
      winning_score: winning_score,
      num_robots: range_from_python(num_robots),
      countdown: countdown,
      config: GameConfig.from_python(config),
      robots: Enum.map(robots, &Robot.from_python/1),
      state: state_from_python(state),
      previous_wins: previous_wins
    }
  end

  defp join_error_from_python("game_in_progress"), do: :game_in_progress
  defp join_error_from_python("game_full"), do: :game_full

  defp state_to_python(:setup), do: "setup"
  defp state_to_python(:counting_down), do: "counting_down"
  defp state_to_python(:playing), do: "playing"
  defp state_to_python(:finished), do: "finished"

  defp state_from_python("setup"), do: :setup
  defp state_from_python("counting_down"), do: :counting_down
  defp state_from_python("playing"), do: :playing
  defp state_from_python("finished"), do: :finished

  defp range_to_python(%Range{} = range) do
    %{
      "first" => range.first,
      "last" => range.last,
      "step" => range.step
    }
  end

  defp range_from_python(%{"first" => first, "last" => last, "step" => step}) do
    first..last//step
  end

  defp range_from_python(%{"first" => first, "last" => last}) do
    first..last
  end
end

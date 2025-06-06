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
  def new(%GameConfig{} = config \\ %GameConfig{}) do
    %__MODULE__{
      id: GameId.new(),
      winning_score: config.winning_score,
      num_robots: config.num_robots,
      countdown: config.countdown,
      config: config
    }
  end

  @type join_error() :: :game_in_progress | :game_full

  @doc """
  Join game.
  """
  @spec join(t(), Robot.t()) :: {:ok, t()} | {:error, join_error()}
  def join(%__MODULE__{state: state}, %Robot{})
      when state in [:counting_down, :playing, :finished] do
    {:error, :game_in_progress}
  end

  def join(
        %__MODULE__{robots: robots, num_robots: %Range{last: max_robots}} = game,
        %Robot{} = robot
      ) do
    if length(robots) >= max_robots do
      {:error, :game_full}
    else
      {:ok, %{game | robots: robots ++ [robot]}}
    end
  end

  @doc """
  Score a point.
  """
  @spec score_point(t(), RobotId.t()) :: t()
  def score_point(%__MODULE__{state: :playing, robots: robots} = game, robot_id() = robot_id) do
    updated_robots =
      Enum.map(robots, fn
        %Robot{id: ^robot_id, score: score} = robot -> %{robot | score: score + 1}
        robot -> robot
      end)

    updated_robot =
      Enum.find(updated_robots, fn %Robot{id: id} -> id == robot_id end)

    game = %{game | robots: updated_robots}

    if updated_robot.score >= game.winning_score do
      %{game | state: :finished}
    else
      game
    end
  end

  def score_point(%__MODULE__{} = game, _), do: game

  @doc """
  List robots by insertion order.
  """
  @spec robots(t()) :: list(Robot.t())
  def robots(%__MODULE__{} = game), do: game.robots

  @doc """
  Is Robot an admin.
  """
  @spec admin?(t(), RobotId.t()) :: boolean()
  def admin?(%__MODULE__{} = game, robot_id() = robot_id) do
    robot =
      case Enum.find(game.robots, fn %Robot{id: id} -> id == robot_id end) do
        nil -> raise KeyError, key: robot_id, term: game.robots
        r -> r
      end

    robot.role == :admin
  end

  @doc """
  Play game.
  """
  @spec play(t()) :: t()
  def play(%__MODULE__{} = game), do: %{game | state: :playing}

  @doc """
  Countdown to start.
  """
  @spec countdown(t()) :: t()
  def countdown(%__MODULE__{state: :setup} = game) do
    %{game | state: :counting_down}
  end

  def countdown(%__MODULE__{countdown: countdown} = game) when countdown > 0 do
    %{game | state: :counting_down, countdown: countdown - 1}
  end

  def countdown(%__MODULE__{countdown: 0} = game) do
    %{game | state: :playing}
  end

  @doc """
  List robots by score in descending order.
  """
  @spec score_board(t()) :: list(Robot.t())
  def score_board(%__MODULE__{robots: robots}) do
    Enum.sort_by(robots, & &1.score, :desc)
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
    %{
      game
      | winning_score: game.config.winning_score,
        num_robots: game.config.num_robots,
        countdown: game.config.countdown,
        robots: reset_robot_scores(game.robots),
        state: :setup,
        previous_wins: save_winner(game)
    }
  end

  @doc """
  Leaderboard

  Robots with scores sorted in descending order.
  """
  @spec leaderboard(t()) :: list({Robot.t(), non_neg_integer()})
  def leaderboard(%__MODULE__{} = game) do
    current_winner_id = winner!(game).id

    game
    |> robots()
    |> Enum.map(fn %Robot{} = robot ->
      previous_win_count = Map.get(game.previous_wins, robot.id, 0)

      win_count =
        if current_winner_id == robot.id do
          previous_win_count + 1
        else
          previous_win_count
        end

      {robot, win_count}
    end)
    |> Enum.sort_by(fn {%Robot{}, score} -> score end, :desc)
  end

  defp reset_robot_scores(robots) do
    Enum.map(robots, fn robot -> %{robot | score: 0} end)
  end

  defp save_winner(%__MODULE__{} = game) do
    Map.update(game.previous_wins, winner!(game).id, 1, &(&1 + 1))
  end
end

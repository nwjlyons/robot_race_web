defmodule RobotRace.Game do
  @moduledoc """
  Game struct and functions.
  """

  import RobotRace.RobotId

  alias RobotRace.GameConfig
  alias RobotRace.GameId
  alias RobotRace.Robot
  alias RobotRace.RobotId
  alias RobotRace.ZigDomain

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
    |> ZigDomain.call(%{config: GameConfig.to_zig(config)})
    |> from_zig()
  end

  @type join_error() :: :game_in_progress | :game_full

  @doc """
  Join game.
  """
  @spec join(t(), Robot.t()) :: {:ok, t()} | {:error, join_error()}
  def join(%__MODULE__{} = game, %Robot{} = robot) do
    case ZigDomain.call(:join, %{game: to_zig(game), robot: Robot.to_zig(robot)}) do
      %{status: :ok, game: updated_game} ->
        {:ok, from_zig(updated_game)}

      %{status: :failed, reason: reason} ->
        {:error, join_error_from_zig(reason)}
    end
  end

  @doc """
  Score a point.
  """
  @spec score_point(t(), RobotId.t()) :: t()
  def score_point(%__MODULE__{} = game, robot_id() = robot_id) do
    :score_point
    |> ZigDomain.call(%{game: to_zig(game), robot_id: robot_id})
    |> from_zig()
  end

  def score_point(%__MODULE__{} = game, _robot_id), do: game

  @doc """
  List robots by insertion order.
  """
  @spec robots(t()) :: list(Robot.t())
  def robots(%__MODULE__{} = game) do
    :robots
    |> ZigDomain.call(%{game: to_zig(game)})
    |> Enum.map(&Robot.from_zig/1)
  end

  @doc """
  Is Robot an admin.
  """
  @spec admin?(t(), RobotId.t()) :: boolean()
  def admin?(%__MODULE__{} = game, robot_id() = robot_id) do
    case ZigDomain.call(:admin, %{game: to_zig(game), robot_id: robot_id}) do
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
    |> ZigDomain.call(%{game: to_zig(game)})
    |> from_zig()
  end

  @doc """
  Countdown to start.
  """
  @spec countdown(t()) :: t()
  def countdown(%__MODULE__{} = game) do
    :countdown
    |> ZigDomain.call(%{game: to_zig(game)})
    |> from_zig()
  end

  @doc """
  List robots by score in descending order.
  """
  @spec score_board(t()) :: list(Robot.t())
  def score_board(%__MODULE__{} = game) do
    :score_board
    |> ZigDomain.call(%{game: to_zig(game)})
    |> Enum.map(&Robot.from_zig/1)
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
    |> ZigDomain.call(%{game: to_zig(game)})
    |> from_zig()
  end

  @doc """
  Leaderboard

  Robots with scores sorted in descending order.
  """
  @spec leaderboard(t()) :: list({Robot.t(), non_neg_integer()})
  def leaderboard(%__MODULE__{} = game) do
    :leaderboard
    |> ZigDomain.call(%{game: to_zig(game)})
    |> Enum.map(fn %{robot: robot, win_count: win_count} ->
      {Robot.from_zig(robot), win_count}
    end)
  end

  @spec to_zig(t()) :: map()
  def to_zig(%__MODULE__{} = game) do
    %{
      id: game.id,
      winning_score: game.winning_score,
      num_robots: range_to_zig(game.num_robots),
      countdown: game.countdown,
      config: GameConfig.to_zig(game.config),
      robots: Enum.map(game.robots, &Robot.to_zig/1),
      state: game.state,
      previous_wins: previous_wins_to_zig(game.previous_wins)
    }
  end

  @spec from_zig(map()) :: t()
  def from_zig(%{
        id: id,
        winning_score: winning_score,
        num_robots: num_robots,
        countdown: countdown,
        config: config,
        robots: robots,
        state: state,
        previous_wins: previous_wins
      }) do
    %__MODULE__{
      id: id,
      winning_score: winning_score,
      num_robots: range_from_zig(num_robots),
      countdown: countdown,
      config: GameConfig.from_zig(config),
      robots: Enum.map(robots, &Robot.from_zig/1),
      state: state,
      previous_wins: previous_wins_from_zig(previous_wins)
    }
  end

  defp join_error_from_zig(:game_in_progress), do: :game_in_progress
  defp join_error_from_zig(:game_full), do: :game_full

  defp range_to_zig(%Range{} = range) do
    %{
      first: range.first,
      last: range.last,
      step: range.step
    }
  end

  defp range_from_zig(%{first: first, last: last, step: step}) do
    first..last//step
  end

  defp previous_wins_to_zig(previous_wins) when is_map(previous_wins) do
    Enum.map(previous_wins, fn {id, wins} -> %{id: id, wins: wins} end)
  end

  defp previous_wins_from_zig(previous_wins) when is_list(previous_wins) do
    Enum.reduce(previous_wins, %{}, fn %{id: id, wins: wins}, acc ->
      Map.put(acc, id, wins)
    end)
  end
end

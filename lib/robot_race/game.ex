defmodule RobotRace.Game do
  @moduledoc """
  Game struct and functions.
  """
  use TypedStruct
  import RobotRace.RobotId

  alias RobotRace.GameConfig
  alias RobotRace.GameId
  alias RobotRace.Robot
  alias RobotRace.RobotId

  typedstruct do
    field :id, GameId.t(), enforce: true
    field :winning_score, pos_integer(), enforce: true
    field :num_robots, Range.t(pos_integer(), pos_integer()), enforce: true
    field :countdown, pos_integer(), enforce: true
    field :config, GameConfig.t(), enforce: true
    field :robots, %{RobotId.t() => Robot.t()}, default: %{}
    field :robots_order, list(RobotId.t()), default: []
    field :state, state(), default: :setup
    field :previous_wins, %{RobotId.t() => non_neg_integer()}, default: %{}
  end

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

  def join(%__MODULE__{robots: %{} = robots, num_robots: %Range{last: max_robots}}, %Robot{})
      when map_size(robots) >= max_robots do
    {:error, :game_full}
  end

  def join(%__MODULE__{} = game, %Robot{} = robot) do
    {:ok,
     %{
       game
       | robots: Map.put(game.robots, robot.id, robot),
         robots_order: game.robots_order ++ [robot.id]
     }}
  end

  @doc """
  Score a point.
  """
  @spec score_point(t(), RobotId.t()) :: t()
  def score_point(%__MODULE__{state: :playing} = game, robot_id() = robot_id) do
    robot = Map.fetch!(game.robots, robot_id)
    robot = %{robot | score: robot.score + 1}
    game = %{game | robots: Map.replace!(game.robots, robot.id, robot)}

    if robot.score >= game.winning_score do
      %{game | state: :finished}
    else
      game
    end
  end

  def score_point(%__MODULE__{} = game, robot_id() = _robot_id), do: game

  @doc """
  List robots by insertion order.
  """
  @spec robots(t()) :: list(Robot.t())
  def robots(%__MODULE__{} = game) do
    Enum.map(game.robots_order, &Map.fetch!(game.robots, &1))
  end

  @doc """
  Is Robot an admin.
  """
  @spec admin?(t(), RobotId.t()) :: boolean()
  def admin?(%__MODULE__{} = game, robot_id() = robot_id) do
    robot = Map.fetch!(game.robots, robot_id)
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
    current_winner_id = winner(game).id

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
    Map.new(robots, fn {id, robot} -> {id, %{robot | score: 0}} end)
  end

  defp save_winner(%__MODULE__{} = game) do
    Map.update(game.previous_wins, winner(game).id, 1, &(&1 + 1))
  end
end

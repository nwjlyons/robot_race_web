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

  @type robot_tuple() :: {RobotId.t(), String.t(), String.t(), non_neg_integer()}

  @type game_tuple() ::
          {GameId.t(), pos_integer(), pos_integer(), pos_integer(), non_neg_integer(),
           {pos_integer(), pos_integer(), pos_integer(), non_neg_integer()}, [robot_tuple()],
           String.t(), %{RobotId.t() => non_neg_integer()}}

  @type leaderboard_tuple() :: {robot_tuple(), non_neg_integer()}

  @doc """
  New game.
  """
  @spec new(GameConfig.t()) :: t()
  def new(%GameConfig{} = config) do
    :robot_race_game.new(
      config.winning_score,
      config.num_robots.first,
      config.num_robots.last,
      config.countdown
    )
    |> from_game_tuple()
  end

  def new(), do: new(%GameConfig{})

  @type join_error() :: :game_in_progress | :game_full

  @doc """
  Join game.
  """
  @spec join(t(), Robot.t()) :: {:ok, t()} | {:error, join_error()}
  def join(%__MODULE__{} = game, %Robot{} = robot) do
    case :robot_race_game.join(to_game_tuple(game), to_robot_tuple(robot)) do
      {:ok, updated_game} -> {:ok, from_game_tuple(updated_game)}
      {:error, "game_in_progress"} -> {:error, :game_in_progress}
      {:error, "game_full"} -> {:error, :game_full}
    end
  end

  @doc """
  Score a point.
  """
  @spec score_point(t(), RobotId.t()) :: t()
  def score_point(%__MODULE__{} = game, robot_id() = robot_id) do
    game
    |> to_game_tuple()
    |> :robot_race_game.score_point(robot_id)
    |> from_game_tuple()
  end

  def score_point(%__MODULE__{} = game, _), do: game

  @doc """
  List robots by insertion order.
  """
  @spec robots(t()) :: list(Robot.t())
  def robots(%__MODULE__{} = game) do
    game
    |> to_game_tuple()
    |> :robot_race_game.robots()
    |> Enum.map(&from_robot_tuple/1)
  end

  @doc """
  Is Robot an admin.
  """
  @spec admin?(t(), RobotId.t()) :: boolean()
  def admin?(%__MODULE__{} = game, robot_id() = robot_id) do
    case :robot_race_game.admin(to_game_tuple(game), robot_id) do
      {:ok, is_admin?} ->
        is_admin?

      {:error, nil} ->
        raise KeyError, key: robot_id, term: game.robots
    end
  end

  @doc """
  Play game.
  """
  @spec play(t()) :: t()
  def play(%__MODULE__{} = game) do
    game
    |> to_game_tuple()
    |> :robot_race_game.play()
    |> from_game_tuple()
  end

  @doc """
  Countdown to start.
  """
  @spec countdown(t()) :: t()
  def countdown(%__MODULE__{} = game) do
    game
    |> to_game_tuple()
    |> :robot_race_game.countdown()
    |> from_game_tuple()
  end

  @doc """
  List robots by score in descending order.
  """
  @spec score_board(t()) :: list(Robot.t())
  def score_board(%__MODULE__{} = game) do
    game
    |> to_game_tuple()
    |> :robot_race_game.score_board()
    |> Enum.map(&from_robot_tuple/1)
  end

  @doc """
  Return winning robot.
  """
  @spec winner!(t()) :: Robot.t()
  def winner!(%__MODULE__{} = game) do
    game
    |> to_game_tuple()
    |> :robot_race_game.winner()
    |> from_robot_tuple()
  end

  @doc """
  Play again.
  """
  @spec play_again(t()) :: t()
  def play_again(%__MODULE__{} = game) do
    game
    |> to_game_tuple()
    |> :robot_race_game.play_again()
    |> from_game_tuple()
  end

  @doc """
  Leaderboard

  Robots with scores sorted in descending order.
  """
  @spec leaderboard(t()) :: list({Robot.t(), non_neg_integer()})
  def leaderboard(%__MODULE__{} = game) do
    game
    |> to_game_tuple()
    |> :robot_race_game.leaderboard()
    |> Enum.map(fn {robot, score} -> {from_robot_tuple(robot), score} end)
  end

  @spec to_game_tuple(t()) :: game_tuple()
  defp to_game_tuple(%__MODULE__{} = game) do
    {
      game.id,
      game.winning_score,
      game.num_robots.first,
      game.num_robots.last,
      game.countdown,
      {
        game.config.winning_score,
        game.config.num_robots.first,
        game.config.num_robots.last,
        game.config.countdown
      },
      Enum.map(game.robots, &to_robot_tuple/1),
      Atom.to_string(game.state),
      game.previous_wins
    }
  end

  @spec from_game_tuple(game_tuple()) :: t()
  defp from_game_tuple(
         {id, winning_score, min_robots, max_robots, countdown,
          {config_winning_score, config_min_robots, config_max_robots, config_countdown}, robots,
          state, previous_wins}
       ) do
    %__MODULE__{
      id: id,
      winning_score: winning_score,
      num_robots: min_robots..max_robots,
      countdown: countdown,
      config: %GameConfig{
        winning_score: config_winning_score,
        num_robots: config_min_robots..config_max_robots,
        countdown: config_countdown
      },
      robots: Enum.map(robots, &from_robot_tuple/1),
      state: state_from_string(state),
      previous_wins: previous_wins
    }
  end

  @spec to_robot_tuple(Robot.t()) :: robot_tuple()
  defp to_robot_tuple(%Robot{id: id, name: name, role: role, score: score}) do
    {id, name, Atom.to_string(role), score}
  end

  @spec from_robot_tuple(robot_tuple()) :: Robot.t()
  defp from_robot_tuple({id, name, role, score}) do
    %Robot{id: id, name: name, role: role_from_string(role), score: score}
  end

  @spec role_from_string(String.t()) :: Robot.role()
  defp role_from_string("admin"), do: :admin
  defp role_from_string(_), do: :guest

  @spec state_from_string(String.t()) :: state()
  defp state_from_string("setup"), do: :setup
  defp state_from_string("counting_down"), do: :counting_down
  defp state_from_string("playing"), do: :playing
  defp state_from_string(_), do: :finished
end

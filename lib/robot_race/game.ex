defmodule RobotRace.Game do
  @moduledoc """
  Game struct and functions.
  """
  alias RobotRace.Id
  alias RobotRace.Robot

  require RobotRace.Id

  @winning_score 25

  @enforce_keys [:id]
  defstruct id: nil, robots: OrderedMap.new(), winning_score: @winning_score, state: :waiting

  @type t :: %__MODULE__{
          id: Id.t(),
          robots: OrderedMap.t(),
          winning_score: pos_integer(),
          state: state()
        }
  @type state :: :waiting | :playing | :finished

  @doc """
  New game.
  """
  @spec new(%{winning_score: pos_integer()}) :: t()
  def new(%{winning_score: winning_score}) when winning_score > 0,
    do: %__MODULE__{id: Id.new(), winning_score: winning_score}

  @spec new() :: t()
  def new(), do: %__MODULE__{id: Id.new()}

  @doc """
  Join game.
  """
  @spec join(t(), Robot.t()) :: t()
  def join(%__MODULE__{robots: robots, state: :waiting} = game, %Robot{} = robot) do
    %__MODULE__{game | robots: OrderedMap.put(robots, robot.id, robot)}
  end

  def join(%__MODULE__{} = game, %Robot{} = _robot), do: game

  @doc """
  Increment robot's score.
  """
  @spec increment(t(), Id.t()) :: t()
  def increment(%__MODULE__{state: :playing} = game, robot_id) when Id.is_id(robot_id) do
    {:ok, robot} = OrderedMap.fetch(game.robots, robot_id)
    robot = %Robot{robot | score: robot.score + 1}
    game = %__MODULE__{game | robots: OrderedMap.put(game.robots, robot.id, robot)}

    if robot.score >= game.winning_score do
      finish(game)
    else
      game
    end
  end

  def increment(%__MODULE__{} = game, _robot_id), do: game

  @doc """
  List robots by score in descending order.
  """
  @spec score_board(t()) :: [Robot.t()]
  def score_board(%__MODULE__{robots: robots}) do
    robots
    |> OrderedMap.values()
    |> Enum.sort_by(fn %Robot{score: score} -> score end, :desc)
  end

  @doc """
  Play game.
  """
  @spec play(t()) :: t()
  def play(%__MODULE__{} = game), do: %__MODULE__{game | state: :playing}

  @doc """
  Play again
  """
  @spec play_again(t()) :: t()
  def play_again(%__MODULE__{} = game) do
    %__MODULE__{game | state: :waiting, robots: reset_robot_scores(game.robots)}
  end

  defp reset_robot_scores(%OrderedMap{} = robots) do
    Enum.reduce(OrderedMap.values(robots), OrderedMap.new(), fn robot, robots ->
      OrderedMap.put(robots, robot.id, %Robot{robot | score: 0})
    end)
  end

  defp finish(%__MODULE__{} = game), do: %__MODULE__{game | state: :finished}
end

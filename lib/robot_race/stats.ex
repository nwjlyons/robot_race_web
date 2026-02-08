defmodule RobotRace.Stats do
  @moduledoc """
  Struct to hold stats about games.
  """

  alias RobotRace.PythonDomain

  defstruct num_games: 0

  @type t() :: %__MODULE__{num_games: non_neg_integer()}

  @spec new() :: t()
  def new() do
    PythonDomain.call(:new_stats)
    |> from_python()
  end

  @spec increment_num_games(t()) :: t()
  def increment_num_games(%__MODULE__{} = stats) do
    :increment_num_games
    |> PythonDomain.call(%{"stats" => to_python(stats)})
    |> from_python()
  end

  @spec to_python(t()) :: map()
  def to_python(%__MODULE__{} = stats) do
    %{"num_games" => stats.num_games}
  end

  @spec from_python(map()) :: t()
  def from_python(%{"num_games" => num_games}) do
    %__MODULE__{num_games: num_games}
  end
end

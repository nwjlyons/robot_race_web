defmodule RobotRace.Stats do
  @moduledoc """
  Struct to hold stats about games.
  """

  alias RobotRace.ZigDomain

  defstruct num_games: 0

  @type t() :: %__MODULE__{num_games: non_neg_integer()}

  @spec new() :: t()
  def new() do
    ZigDomain.call(:new_stats)
    |> from_zig()
  end

  @spec increment_num_games(t()) :: t()
  def increment_num_games(%__MODULE__{} = stats) do
    :increment_num_games
    |> ZigDomain.call(%{stats: to_zig(stats)})
    |> from_zig()
  end

  @spec to_zig(t()) :: map()
  def to_zig(%__MODULE__{} = stats) do
    %{num_games: stats.num_games}
  end

  @spec from_zig(map()) :: t()
  def from_zig(%{num_games: num_games}) do
    %__MODULE__{num_games: num_games}
  end
end

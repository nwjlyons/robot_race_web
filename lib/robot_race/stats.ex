defmodule RobotRace.Stats do
  @moduledoc """
  Struct to hold stats about games.
  """

  defstruct num_games: 0

  @type t() :: %__MODULE__{num_games: non_neg_integer()}
end

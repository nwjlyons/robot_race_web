defmodule RobotRace.Config do
  @moduledoc """
  Configuration for game.
  """
  defstruct winning_score: 25, max_robots: 4, countdown: 3

  @type t() :: %__MODULE__{
          winning_score: pos_integer(),
          max_robots: pos_integer(),
          countdown: pos_integer()
        }
end

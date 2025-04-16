defmodule RobotRace.GameConfig do
  @moduledoc """
  Configuration for game.
  """
  defstruct winning_score: 25,
            num_robots: 2..10,
            countdown: 3

  @type t() :: %__MODULE__{
          winning_score: pos_integer(),
          num_robots: Range.t(pos_integer(), pos_integer()),
          countdown: pos_integer()
        }
end

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

  @spec to_zig(t()) :: map()
  def to_zig(%__MODULE__{} = config) do
    %{
      winning_score: config.winning_score,
      num_robots: range_to_zig(config.num_robots),
      countdown: config.countdown
    }
  end

  @spec from_zig(map()) :: t()
  def from_zig(%{winning_score: winning_score, num_robots: num_robots, countdown: countdown}) do
    %__MODULE__{
      winning_score: winning_score,
      num_robots: range_from_zig(num_robots),
      countdown: countdown
    }
  end

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
end

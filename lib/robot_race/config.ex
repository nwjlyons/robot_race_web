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

  @spec to_python(t()) :: map()
  def to_python(%__MODULE__{} = config) do
    %{
      "winning_score" => config.winning_score,
      "num_robots" => range_to_python(config.num_robots),
      "countdown" => config.countdown
    }
  end

  @spec from_python(map()) :: t()
  def from_python(%{
        "winning_score" => winning_score,
        "num_robots" => num_robots,
        "countdown" => countdown
      }) do
    %__MODULE__{
      winning_score: winning_score,
      num_robots: range_from_python(num_robots),
      countdown: countdown
    }
  end

  defp range_to_python(%Range{} = range) do
    %{
      "first" => range.first,
      "last" => range.last,
      "step" => range.step
    }
  end

  defp range_from_python(%{"first" => first, "last" => last, "step" => step}) do
    first..last//step
  end

  defp range_from_python(%{"first" => first, "last" => last}) do
    first..last
  end
end

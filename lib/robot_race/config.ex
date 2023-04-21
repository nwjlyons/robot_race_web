defmodule RobotRace.GameConfig do
  @moduledoc """
  Configuration for game.
  """
  use TypedStruct

  typedstruct do
    field :winning_score, pos_integer(), default: 25
    field :num_robots, Range.t(pos_integer(), pos_integer()), default: 2..10
    field :countdown, pos_integer(), default: 3
  end
end

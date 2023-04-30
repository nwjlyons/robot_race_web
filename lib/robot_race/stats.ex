defmodule RobotRace.Stats do
  @moduledoc """
  Struct to hold stats about games.
  """

  use TypedStruct

  typedstruct do
    field :num_games, non_neg_integer(), default: 0
  end
end

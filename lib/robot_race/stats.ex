defmodule RobotRace.Stats do
  use TypedStruct

  typedstruct do
    field :num_games, non_neg_integer(), default: 0
  end
end

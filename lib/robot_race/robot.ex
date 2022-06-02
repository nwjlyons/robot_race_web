defmodule RobotRace.Robot do
  @moduledoc """
  Robot.
  """

  alias RobotRace.Id

  @derive {Jason.Encoder, only: [:name, :score]}
  defstruct id: nil, name: "", score: 0

  @type t() :: %__MODULE__{id: Id.t(), name: String.t(), score: pos_integer()}

  @doc """
  Create a robot.
  """
  @spec new(%{name: String.t()}) :: t()
  def new(%{name: name}) when is_binary(name) do
    %__MODULE__{id: Id.new(), name: name}
  end
end

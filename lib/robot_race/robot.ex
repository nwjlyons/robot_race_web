defmodule RobotRace.Robot do
  @moduledoc """
  Robot.
  """
  use TypedStruct

  alias RobotRace.RobotId

  @derive {Jason.Encoder, only: [:name, :score]}

  typedstruct do
    field :id, RobotId.t()
    field :name, String.t()
    field :role, role(), default: :guest
    field :score, non_neg_integer(), default: 0
  end

  @type role() :: :guest | :admin

  @roles [:guest, :admin]

  defguard is_role(role) when role in @roles

  @doc """
  New robot.
  """
  @spec new(String.t(), role()) :: t()
  def new(name, role) when is_binary(name) and is_role(role) do
    %__MODULE__{id: RobotId.new(), name: name, role: role}
  end
end

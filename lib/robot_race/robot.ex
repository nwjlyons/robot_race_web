defmodule RobotRace.Robot do
  @moduledoc """
  Robot.
  """

  alias RobotRace.RobotId

  @derive {JSON.Encoder, only: [:name, :score]}

  defstruct id: nil,
            name: "",
            role: :guest,
            score: 0

  @type t() :: %__MODULE__{
          id: RobotId.t(),
          name: String.t(),
          role: role(),
          score: non_neg_integer()
        }

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

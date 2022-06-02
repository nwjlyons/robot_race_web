defmodule RobotRace.Robot do
  @moduledoc """
  Robot.
  """

  alias RobotRace.Id

  @roles [:guest, :admin]

  @derive {Jason.Encoder, only: [:name, :score]}
  defstruct id: nil, name: "", role: :guest, score: 0

  @type t() :: %__MODULE__{
          id: Id.t(),
          name: String.t(),
          role: role(),
          score: pos_integer()
        }

  @type role() :: :guest | :admin

  defguard is_role(role) when role in @roles

  @doc """
  New robot.
  """
  @spec new(String.t(), role()) :: t()
  def new(name, role) when is_binary(name) and is_role(role) do
    %__MODULE__{id: Id.new(), name: name, role: role}
  end
end

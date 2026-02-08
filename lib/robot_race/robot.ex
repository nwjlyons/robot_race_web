defmodule RobotRace.Robot do
  @moduledoc """
  Robot.
  """

  alias RobotRace.RobotId
  alias RobotRace.ZigDomain

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
    :new_robot
    |> ZigDomain.call(%{name: name, role: role})
    |> from_zig()
  end

  @spec to_zig(t()) :: map()
  def to_zig(%__MODULE__{} = robot) do
    %{
      id: robot.id,
      name: robot.name,
      role: robot.role,
      score: robot.score
    }
  end

  @spec from_zig(map()) :: t()
  def from_zig(%{id: id, name: name, role: role, score: score}) do
    %__MODULE__{
      id: id,
      name: name,
      role: role,
      score: score
    }
  end
end

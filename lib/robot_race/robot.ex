defmodule RobotRace.Robot do
  @moduledoc """
  Robot.
  """

  alias RobotRace.PythonDomain
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
    :new_robot
    |> PythonDomain.call(%{"name" => name, "role" => role_to_python(role)})
    |> from_python()
  end

  @spec to_python(t()) :: map()
  def to_python(%__MODULE__{} = robot) do
    %{
      "id" => robot.id,
      "name" => robot.name,
      "role" => role_to_python(robot.role),
      "score" => robot.score
    }
  end

  @spec from_python(map()) :: t()
  def from_python(%{"id" => id, "name" => name, "role" => role, "score" => score}) do
    %__MODULE__{
      id: id,
      name: name,
      role: role_from_python(role),
      score: score
    }
  end

  defp role_to_python(:guest), do: "guest"
  defp role_to_python(:admin), do: "admin"

  defp role_from_python("guest"), do: :guest
  defp role_from_python("admin"), do: :admin
end

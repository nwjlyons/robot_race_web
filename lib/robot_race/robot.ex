defmodule RobotRace.Robot do
  @moduledoc """
  A module representing a Robot in a Robot Race.

  A Robot has an id, name, role, and score. The role can be either `:guest` or `:admin`.
  """

  alias RobotRace.RobotId

  @roles [:guest, :admin]

  @derive {Jason.Encoder, only: [:name, :score]}
  defstruct id: nil, name: "", role: :guest, score: 0

  @type t() :: %__MODULE__{
          id: RobotId.t(),
          name: String.t(),
          role: role(),
          score: non_neg_integer()
        }

  @type role() :: :guest | :admin

  defguard is_role(role) when role in @roles

  @doc """
  Creates a new Robot instance.

  ## Parameters

  - name: The name of the robot as a binary string.
  - role: The role of the robot, which can be either `:guest` or `:admin`.

  ## Examples

      iex> robot = RobotRace.Robot.new("Robot 1", :guest)
      %RobotRace.Robot{
        id: "some_id",
        name: "Robot 1",
        role: :guest,
        score: 0
      }

  """
  @spec new(String.t(), role()) :: t()
  def new(name, role) when is_binary(name) and is_role(role) do
    %__MODULE__{id: RobotId.new(), name: name, role: role}
  end
end

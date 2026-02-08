defmodule RobotRace.Id do
  @moduledoc false
  @type t() :: String.t()

  @doc """
  Generate new identifier
  """
  @spec new() :: t()
  def new(), do: :robot_race_id.new()
end

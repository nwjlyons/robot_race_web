defmodule RobotRace.Id do
  @moduledoc false

  alias RobotRace.PythonDomain

  @type t() :: String.t()

  @doc """
  Generate new identifier.
  """
  @spec new() :: t()
  def new() do
    PythonDomain.call(:new_id)
  end
end

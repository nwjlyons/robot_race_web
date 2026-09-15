defmodule RobotRace.Id do
  @moduledoc false

  alias RobotRace.ZigDomain

  @type t() :: String.t()

  @doc """
  Generate new identifier.
  """
  @spec new() :: t()
  def new() do
    ZigDomain.call(:new_id)
  end
end

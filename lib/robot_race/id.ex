defmodule RobotRace.Id do
  @moduledoc """
  Identifier.
  """
  @type t() :: String.t()

  @doc """
  Generate new identifier
  """
  @spec new() :: t()
  def new(), do: UUID.uuid4()

  defguard is_id(id) when is_binary(id)
end

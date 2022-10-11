defmodule RobotRace.RobotId do
  @moduledoc """
  Robot identifier.
  """

  @prefix "r_"

  @typedoc "Robot ID prefixed with: #{@prefix}"
  @type t() :: String.t()

  @doc """
  Generate new identifier
  """
  @spec new() :: t()
  def new(), do: @prefix <> RobotRace.Id.new()

  defmacro robot_id() do
    quote do
      unquote(@prefix) <> robot_id
    end
  end
end

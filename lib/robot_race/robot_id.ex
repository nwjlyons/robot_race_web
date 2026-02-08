defmodule RobotRace.RobotId do
  @moduledoc """
  Robot ID.
  """

  alias RobotRace.ZigDomain

  @prefix "r_"

  @typedoc "Robot ID prefixed with: #{@prefix}"
  @type t() :: String.t()

  @doc """
  Generate new robot ID.
  """
  @spec new() :: t()
  def new(), do: ZigDomain.call(:new_robot_id)

  defmacro robot_id() do
    quote do
      unquote(@prefix) <> _robot_id
    end
  end
end

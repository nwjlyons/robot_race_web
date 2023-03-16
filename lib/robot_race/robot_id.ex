defmodule RobotRace.RobotId do
  @prefix "r_"

  @moduledoc """
  A module for generating and handling Robot IDs in the RobotRace application.

  The Robot IDs are prefixed with "#{@prefix}" to differentiate them from other IDs in the application.
  """

  @typedoc "Robot ID prefixed with: #{@prefix}"
  @type t() :: String.t()

  @doc """
  Generate new robot ID.
  """
  @spec new() :: t()
  def new() do
    @prefix <> RobotRace.Id.new()
  end

  @doc """
  Pattern match on Robot IDs

  ## Examples

      def my_function(robot_id() = robot_id) do
        # This function will match if the robot_id has the correct robot prefix.
      end
  """
  @spec robot_id() :: Macro.t()
  defmacro robot_id() do
    quote do
      unquote(@prefix) <> _robot_id
    end
  end
end

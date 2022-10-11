defmodule RobotRace.GameId do
  @moduledoc """
  Game identifier.
  """

  @prefix "g_"

  @typedoc "Game ID prefixed with: #{@prefix}"
  @type t() :: String.t()

  @doc """
  Generate new identifier
  """
  @spec new() :: t()
  def new(), do: @prefix <> RobotRace.Id.new()

  defmacro game_id() do
    quote do
      unquote(@prefix) <> _game_id
    end
  end
end

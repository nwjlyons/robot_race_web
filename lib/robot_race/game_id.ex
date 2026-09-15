defmodule RobotRace.GameId do
  @moduledoc """
  Game ID.
  """

  alias RobotRace.PythonDomain

  @prefix "g_"

  @typedoc "Game ID prefixed with: #{@prefix}"
  @type t() :: String.t()

  @doc """
  Generate new game ID.
  """
  @spec new() :: t()
  def new(), do: PythonDomain.call(:new_game_id)

  defmacro game_id() do
    quote do
      unquote(@prefix) <> _game_id
    end
  end
end

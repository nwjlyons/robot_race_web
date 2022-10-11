defmodule RobotRace.Id do
  @moduledoc false
  @type t() :: String.t()

  @size 10
  @alphabet "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

  @doc """
  Generate new identifier
  """
  @spec new() :: t()
  def new() do
    # ~15 years needed, in order to have a 1% probability of at least one collision.
    # https://zelark.github.io/nano-id-cc/
    Nanoid.generate(@size, @alphabet)
  end
end

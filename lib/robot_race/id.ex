defmodule RobotRace.Id do
  @moduledoc false
  @type t() :: String.t()

  @size 5
  @alphabet "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

  @doc """
  Generate new identifier
  """
  @spec new() :: t()
  def new() do
    # ~4 years needed, in order to have a 1% probability of at least one collision.
    # when generating 1000 IDs per second
    # https://zelark.github.io/nano-id-cc/
    Nanoid.generate(@size, @alphabet)
  end
end

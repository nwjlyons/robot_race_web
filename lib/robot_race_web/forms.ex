defmodule RobotRaceWeb.Forms do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      use TypedEctoSchema
      import Ecto.Changeset
      @primary_key false
    end
  end
end

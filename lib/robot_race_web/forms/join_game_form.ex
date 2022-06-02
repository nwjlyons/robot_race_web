defmodule RobotRaceWeb.JoinGameForm do
  @moduledoc """
  Join game form.
  """
  use RobotRaceWeb.Forms

  embedded_schema do
    field(:name, :string)
  end

  @type t() :: %__MODULE__{name: String.t()}

  def changeset(%{} = params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, max: 5)
  end

  def validate(%{} = params) do
    params
    |> changeset()
    |> Map.put(:action, :validate)
  end

  def submit(%{} = params) do
    params
    |> changeset()
    |> apply_action(:submit)
  end
end

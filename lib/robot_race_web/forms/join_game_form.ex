defmodule RobotRaceWeb.JoinGameForm do
  @moduledoc """
  Join game form.
  """
  use RobotRaceWeb.Forms

  embedded_schema do
    field(:name, :string)
  end

  @type t() :: %__MODULE__{name: String.t()}

  @spec changeset(t(), map()) :: Ecto.Changeset.t(t())
  def changeset(%__MODULE__{} = form, %{} = params) do
    form
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, max: 5)
  end

  @spec validate(t(), map()) :: Ecto.Changeset.t(t())
  def validate(%__MODULE__{} = form, %{} = params) do
    form
    |> changeset(params)
    |> Map.put(:action, :validate)
  end

  @spec submit(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t(t())}
  def submit(%__MODULE__{} = form, %{} = params) do
    form
    |> changeset(params)
    |> apply_action(:submit)
  end
end

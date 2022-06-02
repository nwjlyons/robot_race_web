defmodule RobotRaceWeb.JoinGameForm do
  @moduledoc """
  Join game form.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias RobotRace.Id
  alias RobotRaceWeb.GameServer

  require RobotRace.Id

  @max_robots 4
  @robot_name_max_length 5

  embedded_schema do
    field(:name, :string)
  end

  @type t() :: %__MODULE__{name: robot_name()}

  @typedoc "Robot name. Maximum #{@robot_name_max_length} characters."
  @type robot_name() :: String.t()

  @spec changeset(t()) :: Ecto.Changeset.t(t())
  def changeset(%__MODULE__{} = form, %{} = params \\ %{}) do
    form
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, max: @robot_name_max_length)
  end

  def validate(%Ecto.Changeset{} = changeset) do
    apply_action(changeset, :validate)
  end

  defp validate_player_count(%Ecto.Changeset{} = changeset, game_id) when Id.is_id(game_id) do
    %GameServer{} = game_server = GameServer.get(game_id)

    if game_server.game.robots.size >= @max_robots do
      add_error(changeset, :name, "Game full. #{game_server.game.robots.size} players.")
    else
      changeset
    end
  end

  defp validate_player_count(%Ecto.Changeset{} = changeset, _game_id), do: changeset

  def submit(%Ecto.Changeset{} = changeset, game_id) do
    changeset
    |> validate_player_count(game_id)
    |> apply_action(:submit)
  end
end

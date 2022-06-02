defmodule RobotRaceWeb.GameServer do
  @moduledoc """
  GenServer that holds state for each game.
  """
  @behaviour GenServer

  use GenServer, restart: :transient

  alias RobotRace.Game
  alias RobotRace.Id
  alias RobotRace.Robot

  require RobotRace.Id

  @timeout_in_ms :timer.minutes(10)
  @tick_in_s 1_000
  @short_tick_in_s 200
  @countdown 3

  @enforce_keys [:game, :admin_id]
  defstruct [:game, :admin_id, state: :waiting, countdown: @countdown, countdown_text: "3"]

  @type t() :: %__MODULE__{
          game: Game.t(),
          admin_id: Id.t(),
          state: state(),
          countdown: pos_integer(),
          countdown_text: String.t()
        }
  @type state() :: :waiting | :counting_down | :playing | :finished

  def start_link(%{game: %Game{} = game, admin_id: admin_id}) when Id.is_id(admin_id) do
    game_server = %__MODULE__{game: game, admin_id: admin_id}
    GenServer.start_link(__MODULE__, game_server, name: via_tuple(game.id))
  end

  # Client
  @impl GenServer
  def init(%__MODULE__{} = game_server) do
    ok(game_server)
  end

  @spec exists?(Id.t()) :: boolean()
  def exists?(game_id) when Id.is_id(game_id) do
    case GenServer.whereis(via_tuple(game_id)) do
      pid when is_pid(pid) -> true
      nil -> false
    end
  end

  @spec get(Id.t()) :: t()
  def get(game_id) when Id.is_id(game_id) do
    GenServer.call(via_tuple(game_id), :get)
  end

  @spec join(Id.t(), RobotRace.Robot.t()) :: t()
  def join(game_id, %Robot{} = robot) when Id.is_id(game_id) do
    GenServer.call(via_tuple(game_id), {:join, robot})
  end

  @spec play(Id.t()) :: t()
  def play(game_id) when Id.is_id(game_id) do
    GenServer.call(via_tuple(game_id), :play)
  end

  @spec play_again(Id.t()) :: t()
  def play_again(game_id) when Id.is_id(game_id) do
    GenServer.call(via_tuple(game_id), :play_again)
  end

  @spec increment(Id.t(), Id.t()) :: t()
  def increment(game_id, robot_id) when Id.is_id(game_id) and Id.is_id(robot_id) do
    GenServer.call(via_tuple(game_id), {:increment, robot_id})
  end

  # Server

  @impl GenServer
  def handle_call(:get, _from, %__MODULE__{} = game_server) do
    reply(game_server, game_server)
  end

  def handle_call(
        {:join, %Robot{} = robot},
        _from,
        %__MODULE__{state: :waiting} = game_server
      ) do
    game_server = %__MODULE__{game_server | game: Game.join(game_server.game, robot)}
    broadcast(game_server)
    reply(game_server, game_server)
  end

  def handle_call(:play, _from, %__MODULE__{state: :waiting} = game_server) do
    game_server = %__MODULE__{game_server | state: :counting_down}
    schedule_tick(@tick_in_s)
    broadcast(game_server)
    reply(game_server, game_server)
  end

  def handle_call(:play_again, _from, %__MODULE__{} = game_server) do
    game_server = %__MODULE__{
      game_server
      | state: :waiting,
        countdown: @countdown,
        countdown_text: "3",
        game: Game.play_again(game_server.game)
    }

    broadcast(game_server)
    reply(game_server, game_server)
  end

  def handle_call({:increment, robot_id}, _from, %__MODULE__{} = game_server) do
    game_server = %__MODULE__{game_server | game: Game.increment(game_server.game, robot_id)}
    broadcast(game_server)
    reply(game_server, game_server)
  end

  def handle_call(_msg, _from, game_server), do: reply(nil, game_server)

  @impl GenServer
  def handle_info(:tick, %__MODULE__{countdown: countdown} = game_server) when countdown == 3 do
    game_server = %__MODULE__{game_server | countdown: countdown - 1, countdown_text: "2"}
    broadcast(game_server)
    schedule_tick(@tick_in_s)
    noreply(game_server)
  end

  def handle_info(:tick, %__MODULE__{countdown: countdown} = game_server) when countdown == 2 do
    game_server = %__MODULE__{game_server | countdown: countdown - 1, countdown_text: "1"}
    broadcast(game_server)
    schedule_tick(@tick_in_s)
    noreply(game_server)
  end

  def handle_info(:tick, %__MODULE__{countdown: countdown} = game_server) when countdown == 1 do
    game_server = %__MODULE__{game_server | countdown: countdown - 1, countdown_text: "Go!"}
    broadcast(game_server)
    schedule_tick(@short_tick_in_s)
    noreply(game_server)
  end

  def handle_info(:tick, %__MODULE__{} = game_server) do
    game_server = %__MODULE__{game_server | state: :playing, game: Game.play(game_server.game)}
    broadcast(game_server)
    noreply(game_server)
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  @impl GenServer
  def terminate(:normal, %__MODULE__{} = game_server) do
    RobotRaceWeb.Endpoint.broadcast("game:" <> game_server.game.id, "timeout", nil)
  end

  defp broadcast(%__MODULE__{} = game_server) do
    RobotRaceWeb.Endpoint.broadcast("game:" <> game_server.game.id, "update", %{
      game_server: game_server
    })
  end

  defp via_tuple(game_id) when Id.is_id(game_id) do
    {:global, game_id}
  end

  defp ok(%__MODULE__{} = game_server) do
    {:ok, game_server, @timeout_in_ms}
  end

  defp reply(reply, %__MODULE__{} = game_server) do
    {:reply, reply, game_server, @timeout_in_ms}
  end

  defp noreply(%__MODULE__{} = game_server) do
    {:noreply, game_server, @timeout_in_ms}
  end

  defp schedule_tick(time) when is_integer(time) do
    Process.send_after(self(), :tick, time)
  end
end

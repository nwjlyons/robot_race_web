defmodule RobotRaceWeb.GameServer do
  @moduledoc """
  GameServer.
  """
  use GenServer, restart: :transient

  import RobotRace.GameId
  import RobotRace.RobotId

  alias RobotRace.Game
  alias RobotRace.GameId
  alias RobotRace.Robot
  alias RobotRace.RobotId
  alias RobotRaceWeb.StatsServer

  require Logger

  @timeout_in_ms :timer.minutes(10)

  @doc """
  Create new game server process.
  """
  def new(%Game{} = game) do
    DynamicSupervisor.start_child(RobotRaceWeb.DynamicSupervisor, {__MODULE__, game})
  end

  def start_link(%Game{} = game) do
    GenServer.start_link(__MODULE__, game, name: via_tuple(game.id))
  end

  # Client
  @impl GenServer
  def init(%Game{} = game) do
    Process.flag(:trap_exit, true)
    StatsServer.increment_num_games()
    ok(game)
  end

  @doc """
  Does game exist.
  """
  @spec exists?(GameId.t()) :: boolean()
  def exists?(game_id() = game_id) do
    case GenServer.whereis(via_tuple(game_id)) do
      pid when is_pid(pid) -> true
      nil -> false
    end
  end

  def exists?(_game_id), do: false

  @doc """
  Get game.
  """
  @spec get(GameId.t()) :: Game.t()
  def get(game_id() = game_id) do
    GenServer.call(via_tuple(game_id), :get)
  end

  @doc """
  Join game.
  """
  @spec join(GameId.t(), Robot.t()) ::
          {:ok, Game.t()} | {:error, :game_in_progress} | {:error, :max_robots}
  def join(game_id() = game_id, %Robot{} = robot) do
    GenServer.call(via_tuple(game_id), {:join, robot})
  end

  @doc """
  Countdown to start.
  """
  @spec countdown(GameId.t()) :: Game.t()
  def countdown(game_id() = game_id) do
    GenServer.call(via_tuple(game_id), :countdown)
  end

  @doc """
  Score point.
  """
  @spec score_point(GameId.t(), RobotId.t()) :: Game.t()
  def score_point(game_id() = game_id, robot_id() = robot_id) do
    GenServer.call(via_tuple(game_id), {:score_point, robot_id})
  end

  @doc """
  Reset game, ready to play again.
  """
  @spec play_again(GameId.t()) :: Game.t()
  def play_again(game_id() = game_id) do
    GenServer.call(via_tuple(game_id), :play_again)
  end

  # Server
  @impl GenServer
  def handle_call(:get, _from, %Game{} = game) do
    reply(game, game)
  end

  def handle_call({:join, %Robot{} = robot}, _from, %Game{} = game) do
    case Game.join(game, robot) do
      {:ok, game} ->
        broadcast(game)
        reply({:ok, game}, game)

      error ->
        reply(error, game)
    end
  end

  def handle_call(:countdown, _from, %Game{} = game) do
    game = Game.countdown(game)
    schedule_countdown(1_000)
    broadcast(game)
    reply(game, game)
  end

  def handle_call({:score_point, robot_id}, _from, %Game{} = game) do
    game = Game.score_point(game, robot_id)
    broadcast(game)
    reply(game, game)
  end

  def handle_call(:play_again, _from, %Game{} = game) do
    game = Game.play_again(game)
    broadcast(game)
    reply(game, game)
  end

  def handle_call(_msg, _from, game_server), do: reply(nil, game_server)

  @impl GenServer
  def handle_info(:countdown, %Game{} = game) do
    Logger.debug("counting down id=#{game.id} countdown=#{game.countdown}")
    game = Game.countdown(game)

    case game do
      %Game{state: :counting_down, countdown: countdown} when countdown > 0 ->
        schedule_countdown(1_000)

      %Game{state: :counting_down} ->
        schedule_countdown(200)

      %Game{} ->
        nil
    end

    broadcast(game)
    noreply(game)
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  @impl GenServer
  def terminate(:normal, %Game{} = game) do
    RobotRaceWeb.Endpoint.broadcast("game:" <> game.id, "terminate", nil)
  end

  def subscribe(%Game{} = game) do
    Phoenix.PubSub.subscribe(RobotRaceWeb.PubSub, "game:" <> game.id)
  end

  defp broadcast(%Game{} = game) do
    RobotRaceWeb.Endpoint.broadcast("game:" <> game.id, "update", %{game: game})
  end

  defp via_tuple(game_id) do
    {:global, game_id}
  end

  defp ok(%Game{} = game) do
    {:ok, game, @timeout_in_ms}
  end

  defp reply(reply, %Game{} = game) do
    {:reply, reply, game, @timeout_in_ms}
  end

  defp noreply(%Game{} = game) do
    {:noreply, game, @timeout_in_ms}
  end

  defp schedule_countdown(time) when is_integer(time) do
    Process.send_after(self(), :countdown, time)
  end
end

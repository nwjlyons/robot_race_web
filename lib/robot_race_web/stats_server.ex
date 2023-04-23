defmodule RobotRaceWeb.StatsServer do
  @moduledoc """
  GenServer to hold stats in memory.
  """

  use GenServer

  alias RobotRace.Stats

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %Stats{}, name: StatsServer)
  end

  @impl GenServer
  def init(%Stats{} = stats) do
    {:ok, stats}
  end

  @spec get() :: Stats.t()
  def get() do
    GenServer.call(StatsServer, :get)
  end

  @spec increment_num_games() :: Stats.t()
  def increment_num_games() do
    GenServer.call(StatsServer, :increment_num_games)
  end

  @impl GenServer
  def handle_call(:increment_num_games, _from, %Stats{} = stats) do
    stats = %Stats{stats | num_games: stats.num_games + 1}
    broadcast(stats)
    {:reply, stats, stats}
  end

  def handle_call(:get, _from, %Stats{} = stats) do
    {:reply, stats, stats}
  end

  @event "stats"

  def subscribe() do
    Phoenix.PubSub.subscribe(RobotRaceWeb.PubSub, @event)
  end

  defp broadcast(%Stats{} = stats) do
    RobotRaceWeb.Endpoint.broadcast(@event, "update", %{stats: stats})
  end
end

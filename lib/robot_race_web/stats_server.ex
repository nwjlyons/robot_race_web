defmodule RobotRaceWeb.StatsServer do
  @moduledoc """
  GenServer to hold stats in memory.
  """

  alias RobotRace.Stats

  @spec child_spec(term()) :: Supervisor.child_spec()
  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [[]]},
      restart: :permanent,
      type: :worker
    }
  end

  def start_link(_opts), do: :robot_race_stats_server.start_link()

  @spec get() :: Stats.t()
  def get(), do: :robot_race_stats_server.get()

  @spec increment_num_games() :: Stats.t()
  def increment_num_games(), do: :robot_race_stats_server.increment_num_games()

  def subscribe(), do: :robot_race_stats_server.subscribe()
end

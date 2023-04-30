defmodule RobotRaceWeb.StatsLive do
  @moduledoc """
  LiveView to display game stats.
  """

  use RobotRaceWeb, :live

  alias RobotRace.Stats
  alias RobotRaceWeb.StatsServer

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket) do
    stats = StatsServer.get()
    if connected?(socket), do: StatsServer.subscribe()
    {:ok, assign(socket, stats: stats)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <div class="absolute h-full w-full flex flex-col justify-center items-center z-10">
        <h1 class="text-gray font-mono text-center m-0 text-5">
          <%= @stats.num_games %>
        </h1>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_info(%{topic: "stats", event: "update", payload: %{stats: %Stats{} = stats}}, socket) do
    {:noreply, assign(socket, stats: stats)}
  end
end

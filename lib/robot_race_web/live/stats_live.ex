defmodule RobotRaceWeb.StatsLive do
  use RobotRaceWeb, :live

  alias RobotRaceWeb.StatsServer

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    stats = StatsServer.get()
    socket = assign(socket, stats: stats)
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <div class="absolute h-full w-full flex flex-col justify-center items-center z-10">
        <h1 class="text-gray font-mono text-center m-0 text-5">
          Stats
        </h1>
        <h2 class="text-gray font-mono text-center m-0 text-4"><%= inspect(@stats.num_games) %></h2>
      </div>
    </div>
    """
  end
end

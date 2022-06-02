defmodule RobotRaceWeb.GameLive do
  @moduledoc """
  LiveView page for game where players can race to the top.
  """
  use RobotRaceWeb, :live

  alias RobotRace.Game
  alias RobotRaceWeb.GameServer

  require RobotRace.Id

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= dialogs(assigns) %>
    <canvas
      id="racetrack"
      class="absolute h-full w-full user-select-none"
      phx-update="ignore"
      phx-hook="RaceTrack"
    >
    </canvas>
    """
  end

  defp dialogs(%{game_server: %GameServer{state: :counting_down}} = assigns) do
    ~H"""
    <div class="absolute h-full w-full flex flex-col justify-center items-center z-10">
      <h1 class="text-gray font-mono text-center m-0 text-5"><%= @game_server.countdown_text %></h1>
    </div>
    """
  end

  defp dialogs(%{game_server: %GameServer{game: %Game{state: :waiting}}} = assigns) do
    assigns =
      Map.put(
        assigns,
        :copy_link,
        Routes.game_url(assigns.socket, :show, assigns.game_server.game.id)
      )

    ~H"""
    <div class="absolute h-full w-full flex flex-col justify-center items-center z-10">
      <div class="prose">
        <%= if(@admin?) do %>
          <p class="text-center">Invite players</p>
          <button
            id="copy-share-link"
            class="retro-button sm:p-4 sm:text-base mb-4"
            data-copy-link={@copy_link}
            phx-hook="CopyLink"
          >
            Copy invite link
          </button>
        <% else %>
          <p class="text-center">Get ready</p>
        <% end %>
        <%= if(@admin? && length(OrderedMap.values(@game_server.game.robots)) > 1) do %>
          <button class="retro-button sm:p-4 sm:text-base" phx-click="play">Start countdown</button>
        <% end %>
      </div>
    </div>
    """
  end

  defp dialogs(%{game_server: %GameServer{game: %Game{state: :finished}}} = assigns) do
    ~H"""
    <div class="absolute h-full w-full flex flex-col justify-center items-center z-10 bg-black-opacity-80">
      <h1 class="text-gray font-mono text-center m-0 text-2 mb-4">
        <%= winner_heading(@game_server.game) %>
      </h1>

      <%= if(@admin?) do %>
        <div class="prose">
          <button class="retro-button sm:p-4 sm:text-base" phx-click="play_again">Play again</button>
        </div>
      <% end %>
    </div>
    """
  end

  defp dialogs(assigns), do: ~H"
"

  defp winner_heading(game) do
    [winner | _losers] = Game.score_board(game)
    "#{winner.name} wins!"
  end

  defp admin?(%GameServer{admin_id: admin_id}, robot_id), do: admin_id == robot_id

  @impl Phoenix.LiveView
  def mount(_params, %{"game_id" => game_id, "robot_id" => robot_id}, socket) do
    %GameServer{} = game_server = RobotRaceWeb.GameServer.get(game_id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(RobotRaceWeb.PubSub, "game:" <> game_server.game.id)
    end

    {:ok,
     assign(socket,
       game_server: game_server,
       robot_id: robot_id,
       admin?: admin?(game_server, robot_id)
     )}
  end

  @impl Phoenix.LiveView
  def handle_info(
        %{
          topic: "game:" <> game_id,
          event: "update",
          payload: %{game_server: %GameServer{} = game_server}
        },
        socket
      ) do
    if socket.assigns.game_server.game.id == game_id do
      {:noreply, socket |> assign(game_server: game_server) |> push_game_state()}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{topic: "game:" <> game_id, event: "timeout"}, socket) do
    if socket.assigns.game_server.game.id == game_id do
      {:noreply, redirect(socket, to: Routes.lobby_path(socket, :create))}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("race_track_mounted", _params, socket) do
    {:noreply, push_game_state(socket)}
  end

  def handle_event("play", _params, socket) do
    RobotRaceWeb.GameServer.play(socket.assigns.game_server.game.id)
    {:noreply, socket}
  end

  def handle_event("play_again", _params, socket) do
    RobotRaceWeb.GameServer.play_again(socket.assigns.game_server.game.id)
    {:noreply, socket}
  end

  def handle_event("score_point", %{"source" => "keyboard", "code" => "Space"}, socket) do
    RobotRaceWeb.GameServer.increment(socket.assigns.game_server.game.id, socket.assigns.robot_id)
    {:noreply, socket}
  end

  def handle_event("score_point", %{"source" => "touch"}, socket) do
    RobotRaceWeb.GameServer.increment(socket.assigns.game_server.game.id, socket.assigns.robot_id)
    {:noreply, socket}
  end

  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  defp push_game_state(socket) do
    winning_score = socket.assigns.game_server.game.winning_score
    robots = OrderedMap.values(socket.assigns.game_server.game.robots)

    socket
    |> push_event("game_updated", %{winning_score: winning_score, robots: robots})
  end
end

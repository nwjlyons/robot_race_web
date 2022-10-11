defmodule RobotRaceWeb.GameLive do
  @moduledoc """
  LiveView page to play the game.
  """
  use RobotRaceWeb, :live

  alias RobotRace.Game
  alias RobotRaceWeb.GameServer

  @impl Phoenix.LiveView
  def mount(_params, %{"game_id" => game_id, "robot_id" => robot_id}, socket) do
    %Game{} = game = GameServer.get(game_id)
    if connected?(socket), do: GameServer.subscribe(game)

    {:ok,
     assign(socket,
       game: game,
       robot_id: robot_id,
       admin?: Game.admin?(game, robot_id),
       game_url: url(~p"/#{game.id}")
     )}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= dialogs(assigns) %>
    <.racetrack />
    """
  end

  defp dialogs(%{game: %Game{state: :setup}} = assigns) do
    ~H"""
    <div class="absolute h-full w-full flex flex-col justify-center items-center z-10">
      <div class="prose">
        <p class="text-center"><%= if(@admin?, do: "Invite players", else: "Get ready") %></p>
        <%= if @admin? do %>
          <.button id="copy-share-link" data-copy-link={@game_url} phx-hook="CopyLink">
            Copy invite link
          </.button>
          <.button phx-click="countdown">Start countdown</.button>
        <% end %>
      </div>
    </div>
    """
  end

  defp dialogs(%{game: %Game{state: :counting_down, countdown: countdown}} = assigns) do
    ~H"""
    <div class="absolute h-full w-full flex flex-col justify-center items-center z-10">
      <h1 class="text-gray font-mono text-center m-0 text-5">
        <%= countdown_text(countdown) %>
      </h1>
    </div>
    """
  end

  defp dialogs(%{game: %Game{state: :finished}} = assigns) do
    ~H"""
    <div class="absolute h-full w-full flex flex-col justify-center items-center z-10 bg-black-opacity-80">
      <h1 class="text-gray font-mono text-center m-0 text-2 mb-4">
        <%= Game.winner(@game).name %> wins!
      </h1>

      <div :if={@admin?} class="prose">
        <button class="retro-button sm:p-4 sm:text-base" phx-click="play_again">Play again</button>
      </div>
    </div>
    """
  end

  defp dialogs(assigns), do: ~H""

  @impl Phoenix.LiveView
  def handle_event("race_track_mounted", _params, socket) do
    {:noreply, push_game_state(socket)}
  end

  def handle_event("countdown", _params, socket) do
    GameServer.countdown(socket.assigns.game.id)
    {:noreply, socket}
  end

  def handle_event("play_again", _params, socket) do
    GameServer.play_again(socket.assigns.game.id)
    {:noreply, socket}
  end

  def handle_event("score_point", %{"source" => "keyboard", "code" => "Space"}, socket) do
    GameServer.score_point(socket.assigns.game.id, socket.assigns.robot_id)
    {:noreply, socket}
  end

  def handle_event("score_point", %{"source" => "touch"}, socket) do
    GameServer.score_point(socket.assigns.game.id, socket.assigns.robot_id)
    {:noreply, socket}
  end

  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(
        %{topic: "game:" <> game_id, event: "update", payload: %{game: %Game{} = game}},
        socket
      ) do
    if socket.assigns.game.id == game_id do
      {
        :noreply,
        socket
        |> assign(game: game)
        |> push_game_state()
      }
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{topic: "game:" <> game_id, event: "timeout"}, socket) do
    if socket.assigns.game.id == game_id do
      {:noreply, redirect(socket, to: ~p"/")}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp countdown_text(countdown) when countdown > 0, do: Integer.to_string(countdown)
  defp countdown_text(_countdown), do: "Go"

  defp push_game_state(%{assigns: %{game: %Game{} = game}} = socket) do
    push_event(socket, "game_updated", %{
      winning_score: game.winning_score,
      robots: Game.robots(socket.assigns.game)
    })
  end
end

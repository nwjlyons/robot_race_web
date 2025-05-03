defmodule RobotRaceWeb.GameLive do
  @moduledoc """
  LiveView page to play the game.
  """
  use RobotRaceWeb, :live

  alias RobotRace.Game
  alias RobotRace.Robot
  alias RobotRaceWeb.GameServer

  @impl Phoenix.LiveView
  def mount(_params, %{"game_id" => game_id, "robot_id" => robot_id}, %Socket{} = socket) do
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
    <%= case @game.state do %>
      <% :setup -> %>
        <.dialog>
          <div class="prose">
            <p class="text-center">{if(@admin?, do: "Invite players", else: "Get ready")}</p>
            <%= if @admin? do %>
              <.button id="copy-share-link" data-copy-link={@game_url} phx-hook="CopyLink" class={["mb-2"]}>
                Copy invite link
              </.button>
              <.button phx-click="start_countdown">Start countdown</.button>
            <% end %>
          </div>
        </.dialog>
      <% :counting_down -> %>
        <.dialog>
          <h1 class="text-gray font-mono text-center m-0 text-5">
            {countdown_text(@game.countdown)}
          </h1>
        </.dialog>
      <% :finished -> %>
        <.dialog>
          <h1 class="text-center m-0 mb-4">
            <div class="text-gray font-mono text-4">{Game.winner!(@game).name} wins!</div>
            <div class="p-4">
              <div class="text-center font-mono text-darkgray">Leaderboard</div>
              <div
                :for={{%Robot{} = robot, win_count} <- Game.leaderboard(@game)}
                class="flex justify-between"
              >
                <div class="text-darkgray font-mono">{robot.name}</div>
                <div class="text-darkgray font-mono">{win_count}</div>
              </div>
            </div>
          </h1>

          <div :if={@admin?} class="prose">
            <button class="retro-button sm:p-4 sm:text-base" phx-click="play_again">
              Play again
            </button>
          </div>
        </.dialog>
      <% _other -> %>
    <% end %>
    <.racetrack />
    """
  end

  @impl Phoenix.LiveView
  def handle_event("race_track_mounted", _params, %Socket{} = socket) do
    {:noreply, push_game_state(socket)}
  end

  def handle_event("start_countdown", _params, %Socket{} = socket) do
    if socket.assigns.admin? do
      GameServer.countdown(socket.assigns.game.id)
      {:noreply, socket}
    else
      {:noreply, permission_denied(socket)}
    end
  end

  def handle_event("play_again", _params, %Socket{} = socket) do
    if socket.assigns.admin? do
      GameServer.play_again(socket.assigns.game.id)
      {:noreply, socket}
    else
      {:noreply, permission_denied(socket)}
    end
  end

  def handle_event(
        "score_point",
        %{"source" => "keyboard", "code" => "Space"},
        %Socket{} = socket
      ) do
    GameServer.score_point(socket.assigns.game.id, socket.assigns.robot_id)
    {:noreply, socket}
  end

  def handle_event("score_point", %{"source" => "touch"}, %Socket{} = socket) do
    GameServer.score_point(socket.assigns.game.id, socket.assigns.robot_id)
    {:noreply, socket}
  end

  def handle_event(_event, _params, %Socket{} = socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(
        %{topic: "game:" <> game_id, event: "update", payload: %{game: %Game{} = game}},
        %Socket{} = socket
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

  def handle_info(%{topic: "game:" <> game_id, event: "terminate"}, %Socket{} = socket) do
    if socket.assigns.game.id == game_id do
      {:noreply, socket |> put_flash(:error, "terminated") |> redirect(to: ~p"/")}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_msg, %Socket{} = socket) do
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

  defp permission_denied(%Socket{} = socket) do
    put_flash(socket, :error, "permission denied")
  end
end

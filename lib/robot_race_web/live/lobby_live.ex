defmodule RobotRaceWeb.LobbyLive do
  @moduledoc """
  LiveView page to create or join a game.
  """
  use RobotRaceWeb, :live

  alias RobotRace.Robot
  alias RobotRaceWeb.JoinGameForm

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <canvas
      id="racetrack"
      class="absolute h-full w-full user-select-none"
      phx-update="ignore"
      phx-hook="RaceTrack"
    >
    </canvas>
    <div class="absolute h-full w-full flex flex-col justify-center items-center">
      <div class="p-4">
        <div class="sm:mb-8">
          <h1 class="text-gray font-mono text-shadow-green text-center text-6xl sm:text-7xl m-0">
            Robot
            <br />
            Race
          </h1>
        </div>
        <div class="sm:mb-8">
          <div class="prose text-xs sm:text-base text-center">
            <p>2 - 4 players</p>
            <p>First to the top wins!</p>
            <p>Hit spacebar or tap screen to race</p>
          </div>
        </div>
        <div>
          <.form
            let={f}
            for={@changeset}
            phx-change="validate"
            phx-submit="submit"
            phx-trigger-action={@trigger_action}
            action={@form_action}
          >
            <div class="mb-4">
              <%= error_tag(f, :name) %>
              <%= text_input(f, :name,
                autofocus: true,
                placeholder: "Name",
                class: "retro-text-input sm:p-4",
                maxlength: 6
              ) %>
            </div>
            <div>
              <%= submit(@submit_text, class: "retro-button sm:p-4 sm:text-base") %>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    {:ok,
     assign(socket,
       changeset: JoinGameForm.changeset(%JoinGameForm{}),
       game_id: Map.get(params, "id"),
       form_action: form_action(socket, params),
       submit_text: if(joining?(params), do: "Join", else: "Start new game"),
       trigger_action: false
     )}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"join_game_form" => join_game_form}, socket) do
    changeset = JoinGameForm.changeset(%JoinGameForm{}, join_game_form)

    case JoinGameForm.validate(changeset) do
      {:ok, join_game_form_schema} ->
        {:noreply, assign(socket, changeset: JoinGameForm.changeset(join_game_form_schema))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("submit", %{"join_game_form" => join_game_form}, socket) do
    changeset = JoinGameForm.changeset(%JoinGameForm{}, join_game_form)

    case JoinGameForm.submit(changeset, socket.assigns.game_id) do
      {:ok, join_game_form_schema} ->
        {:noreply,
         assign(socket,
           changeset: JoinGameForm.changeset(join_game_form_schema),
           trigger_action: true
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("race_track_mounted", _params, socket) do
    {
      :noreply,
      push_event(socket, "game_updated", %{
        winning_score: 25,
        robots: [%Robot{score: 0}, %Robot{score: 0}]
      })
    }
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  defp form_action(%Phoenix.LiveView.Socket{} = socket, %{"id" => id}),
    do: Routes.game_path(socket, :update, id)

  defp form_action(%Phoenix.LiveView.Socket{} = socket, _params),
    do: Routes.game_path(socket, :create)

  defp joining?(%{"id" => _id}), do: true
  defp joining?(_params), do: false
end

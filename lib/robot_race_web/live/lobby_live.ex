defmodule RobotRaceWeb.LobbyLive do
  @moduledoc """
  LiveView page to create or join a game.
  """
  use RobotRaceWeb, :live

  alias RobotRace.Robot
  alias RobotRaceWeb.JoinGameForm

  @impl Phoenix.LiveView
  def mount(%{} = params, %{} = _session, %Socket{} = socket) do
    game_id = Map.get(params, "id")
    form = %JoinGameForm{}

    {:ok,
     assign(socket,
       form: form,
       changeset: JoinGameForm.changeset(form, %{}),
       game_id: game_id,
       joining?: !!game_id,
       form_action: form_action(game_id),
       trigger_action: false,
       config: %RobotRace.GameConfig{}
     )}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.racetrack />
    <div class="absolute h-full w-full flex flex-col justify-center items-center">
      <div class="p-4">
        <div class="sm:mb-8 text-center">
          <h1 class="text-gray font-mono text-shadow-green inline-block text-6xl sm:text-7xl m-0">
            Robot <br /> Race
          </h1>
        </div>
        <div class="sm:mb-8">
          <div class="prose text-xs sm:text-base text-center">
            <p><%= @config.num_robots.first %> - <%= @config.num_robots.last %> players</p>
            <p>First to the top wins!</p>
            <p>Hit spacebar or tap screen to race</p>
          </div>
        </div>
        <div>
          <.form
            :let={f}
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
              <.button><%= if(@joining?, do: "Join", else: "Start new game") %></.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"join_game_form" => form_params}, %Socket{} = socket) do
    changeset = JoinGameForm.validate(socket.assigns.form, form_params)
    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("submit", %{"join_game_form" => form_params}, %Socket{} = socket) do
    case JoinGameForm.submit(socket.assigns.form, form_params) do
      {:ok, %JoinGameForm{} = _form} ->
        {:noreply, assign(socket, trigger_action: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("race_track_mounted", %{} = _params, %Socket{} = socket) do
    {
      :noreply,
      push_event(socket, "game_updated", %{
        winning_score: 25,
        robots: [%Robot{score: 0}, %Robot{score: 0}]
      })
    }
  end

  def handle_event(_event, %{} = _params, %Socket{} = socket), do: {:noreply, socket}

  defp form_action(nil),
    do: ~p"/"

  defp form_action(id),
    do: ~p"/#{id}"
end

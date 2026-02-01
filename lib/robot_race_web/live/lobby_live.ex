defmodule RobotRaceWeb.LobbyLive do
  @moduledoc """
  LiveView page to create or join a game.
  """
  use RobotRaceWeb, :live

  alias RobotRace.Robot
  alias RobotRaceWeb.JoinGameForm

  # Simulation constants
  @winning_score 25
  # Run simulation steps every 1000ms (1 second)
  @simulation_interval 200

  @impl Phoenix.LiveView
  def mount(%{} = params, %{} = _session, %Socket{} = socket) do
    game_id = Map.get(params, "id")
    form_schema = %JoinGameForm{}

    {:ok,
     socket
     |> assign(
       form_schema: form_schema,
       game_id: game_id,
       joining?: !!game_id,
       form_action: form_action(game_id),
       trigger_action: false,
       config: %RobotRace.GameConfig{},
       robots: initialize_demo_robots(),
       simulation_running: false
     )
     |> assign_form(JoinGameForm.changeset(form_schema, %{}))}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.racetrack />
    <div class="absolute h-full w-full flex flex-col justify-center items-center">
      <div class="p-4">
        <div class="sm:mb-8 text-center">
          <h1 class="text-retro-gray font-mono inline-block text-[3.5rem] sm:text-[5rem] m-0 [text-shadow:0_0_0.5rem_#ffffff,_0_0_1.5rem_#00ffaa,_1px_1px_0rem_#00ffaa]">
            Robot <br /> Race
          </h1>
        </div>
        <div class="sm:mb-8">
          <div class="font-mono text-retro-gray [text-shadow:0_0_1rem_#d3d3d3] text-xs sm:text-base text-center">
            <p>{@config.num_robots.first} - {@config.num_robots.last} players</p>
            <p>First to the top wins!</p>
            <p>Hit spacebar or tap screen to race</p>
          </div>
        </div>
        <div>
          <.form
            for={@form}
            phx-change="validate"
            phx-submit="submit"
            phx-trigger-action={@trigger_action}
            action={@form_action}
          >
            <div class="mb-4">
              {error_tag(@form, :name)}
              <.input
                field={@form[:name]}
                autofocus
                placeholder="Name"
                class="w-full text-center font-mono text-base p-2 sm:p-4 outline-none border-[0.25rem] border-solid border-t-retro-dark-gray border-l-retro-dark-gray border-r-retro-gray border-b-retro-gray bg-white text-retro-black"
                maxlength="6"
              />
            </div>
            <div>
              <.button>{if(@joining?, do: "Join", else: "Start new game")}</.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"join_game_form" => %{} = form_params}, %Socket{} = socket) do
    changeset = JoinGameForm.validate(socket.assigns.form_schema, form_params)
    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("submit", %{"join_game_form" => %{} = form_params}, %Socket{} = socket) do
    case JoinGameForm.submit(socket.assigns.form_schema, form_params) do
      {:ok, %JoinGameForm{} = _form_schema} ->
        {:noreply, assign(socket, trigger_action: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("race_track_mounted", %{} = _params, %Socket{} = socket) do
    if not socket.assigns.simulation_running do
      Process.send_after(self(), :simulation_tick, 500)

      {
        :noreply,
        socket
        |> assign(simulation_running: true)
        |> push_event(
          "game_updated",
          %{
            winning_score: @winning_score,
            robots: socket.assigns.robots
          }
        )
      }
    else
      {:noreply, socket}
    end
  end

  def handle_event(_event, _params, %Socket{} = socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_info(:simulation_tick, socket) do
    updated_robots = simulate_race_step(socket.assigns.robots)
    race_finished = Enum.any?(updated_robots, fn robot -> robot.score >= @winning_score end)

    # Schedule next tick if race is not finished
    if !race_finished do
      Process.send_after(self(), :simulation_tick, @simulation_interval)
    end

    # Check if we need to restart with new robots after a delay
    if race_finished do
      Process.send_after(self(), :restart_simulation, 3000)
    end

    {
      :noreply,
      socket
      |> assign(robots: updated_robots)
      |> push_event(
        "game_updated",
        %{
          winning_score: @winning_score,
          robots: updated_robots
        }
      )
    }
  end

  def handle_info(:restart_simulation, socket) do
    new_robots = initialize_demo_robots()
    Process.send_after(self(), :simulation_tick, @simulation_interval)

    {
      :noreply,
      socket
      |> assign(robots: new_robots)
      |> push_event(
        "game_updated",
        %{
          winning_score: @winning_score,
          robots: new_robots
        }
      )
    }
  end

  defp assign_form(%Socket{} = socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp form_action(nil),
    do: ~p"/"

  defp form_action(id),
    do: ~p"/#{id}"

  # Initialize 2-4 robots with names for the demo animation
  defp initialize_demo_robots do
    #    num_robots = Enum.random(2..4)

    1..4
    |> Enum.map(fn _i ->
      Robot.new("", :guest)
    end)
  end

  # Simulate one step of the race with random movements
  defp simulate_race_step(robots) do
    robots
    |> Enum.map(fn robot ->
      # Each robot has a chance to move up 0, 1, or 2 spaces
      # Using weighted randomness to make the race interesting
      score_increase =
        case :rand.uniform(10) do
          # 10% chance to not move (stuck)
          1 -> 0
          # 60% chance to move 1 space (normal)
          n when n in 2..7 -> 1
          # 30% chance to move 2 spaces (boost)
          _ -> 2
        end

      # Ensure we don't exceed the winning score
      new_score = min(robot.score + score_increase, @winning_score)

      %{robot | score: new_score}
    end)
  end
end

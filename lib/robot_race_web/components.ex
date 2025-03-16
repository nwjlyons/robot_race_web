defmodule RobotRaceWeb.Components do
  @moduledoc """
  Robot Race Components.
  """
  use Phoenix.Component

  @doc """
  Alert used for flash messages
  """
  attr :msg, :string, required: true

  def alert(assigns) do
    ~H"""
    <div class="text-red font-mono flex flex-col items-center w-full p-4 z-10 h-fit">
      {@msg}
    </div>
    """
  end

  @doc """
  Button component.
  """
  attr :text, :string, doc: "Button text"
  attr :rest, :global

  slot :inner_block, required: true, doc: "Inner HTML. Takes precedence over button text."

  def button(assigns) do
    ~H"""
    <button class="retro-button sm:p-4 sm:text-base" {@rest}>
      {render_slot(@inner_block) || @text}
    </button>
    """
  end

  @doc """
  Racetrack component.
  """
  def racetrack(assigns) do
    ~H"""
    <canvas
      id="racetrack"
      class="absolute h-full w-full user-select-none"
      phx-update="ignore"
      phx-hook="RaceTrack"
    >
    </canvas>
    """
  end

  slot :inner_block, required: true

  def dialog(assigns) do
    ~H"""
    <div class="absolute h-full w-full flex flex-col justify-center items-center z-10">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField
  attr :type, :string, values: ["text", "password"], default: "text"

  attr :id, :string
  attr :name, :string
  attr :value, :any
  attr :rest, :global, include: ~w(maxlength)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:id, fn -> field.id end)
    |> assign_new(:value, fn -> field.value end)
    |> assign_new(:name, fn -> field.name end)
    |> input()
  end

  def input(assigns) do
    ~H"""
    <input id={@id} type={@type} name={@name} value={@value} {@rest} />
    """
  end
end

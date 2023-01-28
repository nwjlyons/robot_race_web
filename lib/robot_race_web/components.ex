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
      <%= @msg %>
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
      <%= render_slot(@inner_block) || @text %>
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
end

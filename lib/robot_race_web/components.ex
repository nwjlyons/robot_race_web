defmodule RobotRaceWeb.Components do
  @moduledoc """
  Robot Race Components.
  """
  use Phoenix.Component

  @doc """
  Alert used for flash messages
  """

  def alert(assigns) do
    ~H"""
    <div class="text-red font-mono flex flex-col items-center w-full p-4 z-10">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Button component.
  """
  attr :rest, :global

  def button(assigns) do
    ~H"""
    <button class="retro-button sm:p-4 sm:text-base" {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

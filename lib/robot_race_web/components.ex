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
    <div class="text-red font-mono flex flex-col items-center w-full p-4 z-10">
      <%= @msg %>
    </div>
    """
  end

  @doc """
  Button component.
  """
  attr :value, :string, required: true
  attr :type, :string, default: "submit"

  def button(assigns) do
    ~H"""
    <button class="retro-button sm:p-4 sm:text-base" type={@type}>
      <%= @value %>
    </button>
    """
  end
end

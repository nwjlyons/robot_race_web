defmodule RobotRaceWeb.Components do
  @moduledoc """
  Robot Race Components.
  """
  use Phoenix.Component

  @doc """
  Alert used for flash messages
  """
  @spec alert(%{:msg => String.t()}) :: Phoenix.LiveView.Rendered.t()
  def alert(%{msg: _msg} = assigns) do
    ~H"""
    <div class="absolute text-red font-mono flex flex-col items-center w-full p-4 z-10">
      <%= @msg %>
    </div>
    """
  end
end

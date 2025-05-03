defmodule RobotRaceWeb do
  @moduledoc false

  def static_paths(), do: ~w(assets fonts images favicon.ico robots.txt)

  def controller() do
    quote do
      use Phoenix.Controller

      use Phoenix.VerifiedRoutes,
        endpoint: RobotRaceWeb.Endpoint,
        router: RobotRaceWeb.Router,
        statics: RobotRaceWeb.static_paths()
    end
  end

  def live() do
    quote do
      use Phoenix.LiveView, layout: {RobotRaceWeb.LayoutView, :live}
      alias Phoenix.LiveView
      alias Phoenix.LiveView.Socket

      unquote(view_helpers())
    end
  end

  def view() do
    quote do
      use Phoenix.View,
        root: "lib/robot_race_web/templates",
        namespace: RobotRaceWeb

      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      unquote(view_helpers())
    end
  end

  defp view_helpers() do
    quote do
      import Phoenix.LiveView.Helpers
      import RobotRaceWeb.ErrorHelpers

      use PhoenixHTMLHelpers

      use Phoenix.VerifiedRoutes,
        endpoint: RobotRaceWeb.Endpoint,
        router: RobotRaceWeb.Router,
        statics: RobotRaceWeb.static_paths()

      import Phoenix.Component
      import RobotRaceWeb.Components
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

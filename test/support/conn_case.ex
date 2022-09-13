defmodule RobotRaceWeb.ConnCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      use Phoenix.VerifiedRoutes,
        endpoint: RobotRaceWeb.Endpoint,
        router: RobotRaceWeb.Router,
        statics: RobotRaceWeb.static_paths()
      @endpoint RobotRaceWeb.Endpoint
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end

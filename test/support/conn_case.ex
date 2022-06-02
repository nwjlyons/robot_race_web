defmodule RobotRaceWeb.ConnCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      alias RobotRaceWeb.Router.Helpers, as: Routes
      @endpoint RobotRaceWeb.Endpoint
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end

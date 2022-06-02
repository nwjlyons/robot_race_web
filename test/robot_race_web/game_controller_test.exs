defmodule RobotRaceWeb.GameControllerTest do
  use RobotRaceWeb.ConnCase
  alias RobotRaceWeb.GameServer

  describe "create/2" do
    test "creates and redirects to game", %{conn: conn} do
      conn =
        post(
          conn,
          Routes.game_path(conn, :create),
          %{"join_game_form" => %{"name" => "Bender"}}
        )

      game_id = conn.assigns.game_id
      assert GameServer.exists?(conn.assigns.game_id)
      assert redirected_to(conn) =~ Routes.game_path(conn, :show, game_id)
    end
  end
end

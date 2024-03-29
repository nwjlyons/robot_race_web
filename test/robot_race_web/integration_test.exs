defmodule RobotRaceWeb.IntegrationTest do
  use RobotRaceWeb.ConnCase
  alias RobotRaceWeb.GameServer

  test "integration test", %{conn: conn} do
    conn_bender =
      post(
        conn,
        ~p"/",
        %{"join_game_form" => %{"name" => "Bender"}}
      )

    game_id = conn_bender.assigns.game_id
    assert GameServer.exists?(conn_bender.assigns.game_id)
    assert redirected_to(conn_bender) =~ ~p"/#{game_id}"

    _conn_r2d2 =
      get(
        conn,
        ~p"/#{game_id}/join",
        %{"join_game_form" => %{"name" => "Bender"}}
      )

    game_id = conn_bender.assigns.game_id
    assert GameServer.exists?(conn_bender.assigns.game_id)
    assert redirected_to(conn_bender) =~ ~p"/#{game_id}"
  end

  #  test "create game"
  #  test "redirected to join form"
end

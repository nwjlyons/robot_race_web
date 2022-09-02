defmodule RobotRaceWeb.IntegrationTest do
  use RobotRaceWeb.ConnCase
  alias RobotRaceWeb.GameServer

  test "integration test", %{conn: conn} do
    conn_bender =
      post(
        conn,
        Routes.game_path(conn, :create),
        %{"join_game_form" => %{"name" => "Bender"}}
      )

    game_id = conn_bender.assigns.game_id
    assert GameServer.exists?(conn_bender.assigns.game_id)
    assert redirected_to(conn_bender) =~ Routes.game_path(conn_bender, :show, game_id)

    conn_r2d2 =
      get(
        conn,
        Routes.game_path(conn, :join, game_id),
        %{"join_game_form" => %{"name" => "Bender"}}
      )

    game_id = conn_bender.assigns.game_id
    assert GameServer.exists?(conn_bender.assigns.game_id)
    assert redirected_to(conn_bender) =~ Routes.game_path(conn_bender, :show, game_id)
  end

  #  test "create game"
  #  test "redirected to join form"
end

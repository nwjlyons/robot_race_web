defmodule RobotRaceWeb.GameServerTest do
  use ExUnit.Case

  alias RobotRace.Config
  alias RobotRace.Game
  alias RobotRace.Robot
  alias RobotRaceWeb.GameServer

  setup do
    %{
      game: Game.new(),
      bender: Robot.new("Bender", :admin),
      r2d2: Robot.new("R2-D2", :guest),
      c3po: Robot.new("C-3PO", :guest)
    }
  end

  describe "new/1" do
    test "creates game", %{game: game} do
      refute GameServer.exists?(game.id)
      {:ok, _pid} = GameServer.new(game)
      assert GameServer.exists?(game.id)
    end
  end

  describe "get/1" do
    test "gets game", %{game: %Game{id: id} = game} do
      {:ok, _pid} = GameServer.new(game)
      assert %Game{id: ^id} = GameServer.get(id)
    end
  end

  describe "join/2" do
    test "join game", %{bender: bender, game: %Game{id: id} = game} do
      GameServer.new(game)
      assert {:ok, %Game{}} = GameServer.join(id, bender)
    end

    test "join in progress game", %{bender: bender} do
      game = Game.new() |> Game.play()
      GameServer.new(game)
      assert {:error, :game_in_progress} = GameServer.join(game.id, bender)
    end

    test "join full game", %{bender: bender, r2d2: r2d2} do
      game = Game.new(%Config{max_robots: 1})
      {:ok, game} = Game.join(game, bender)
      GameServer.new(game)
      assert {:error, :max_robots} = GameServer.join(game.id, r2d2)
    end
  end

  describe "countdown/1" do
    test "counts down to start playing" do
      game = Game.new(%Config{countdown: 2})
      GameServer.new(game)
      GameServer.countdown(game.id)
      Process.sleep(5_000)
      assert %Game{state: :playing} = GameServer.get(game.id)
    end
  end

  describe "score_point/2" do
    test "scores point", %{bender: bender} do
      game = Game.new()
      {:ok, game} = Game.join(game, bender)
      game = Game.play(game)
      GameServer.new(game)
      assert %Game{} = game = GameServer.score_point(game.id, bender.id)
      assert [%Robot{score: 1}] = Game.robots(game)
    end
  end
end

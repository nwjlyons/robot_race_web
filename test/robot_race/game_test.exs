defmodule RobotRace.GameTest do
  use ExUnit.Case

  alias RobotRace.Game
  alias RobotRace.GameConfig
  alias RobotRace.Robot

  setup do
    %{
      bender: Robot.new("Bender", :admin),
      r2d2: Robot.new("R2-D2", :guest),
      c3po: Robot.new("C-3PO", :guest)
    }
  end

  describe "new/1" do
    test "with max robots" do
      config = %GameConfig{num_robots: 2..42}
      assert %Game{num_robots: 2..42, config: ^config} = Game.new(config)
    end

    test "with winning score" do
      config = %GameConfig{winning_score: 42}
      assert %Game{winning_score: 42, config: ^config} = Game.new(config)
    end

    test "with countdown" do
      config = %GameConfig{countdown: 42}
      assert %Game{countdown: 42, config: ^config} = Game.new(config)
    end

    test "defaults" do
      config = %GameConfig{}

      assert %Game{num_robots: 2..10, countdown: 3, winning_score: 25, config: ^config} =
               Game.new()
    end
  end

  describe "join/2" do
    test "adds robot", %{bender: bender} do
      assert {:ok, game} = Game.new() |> Game.join(bender)
      assert [^bender] = Game.robots(game)
    end

    test "does not add robot while game is counting down", %{bender: bender} do
      assert {:error, :game_in_progress} = Game.new() |> Game.countdown() |> Game.join(bender)
    end

    test "does not add robot while game is in progress", %{bender: bender} do
      assert {:error, :game_in_progress} = Game.new() |> Game.play() |> Game.join(bender)
    end

    test "does not add robot while game has max robots", %{bender: bender} do
      assert {:error, :game_full} = Game.new(%GameConfig{num_robots: 0..0}) |> Game.join(bender)
    end
  end

  describe "countdown/1" do
    test "counts down and transitions to playing" do
      countdown = 5
      game = Game.new(%GameConfig{countdown: countdown})

      game =
        for i <- countdown..0//-1, reduce: %Game{} = game do
          %Game{} = game ->
            assert %Game{countdown: ^i} = Game.countdown(game)
        end

      assert %Game{countdown: 0, state: :playing} = Game.countdown(game)
    end
  end

  describe "robots/1" do
    test "returns robots in insertion order", %{bender: bender, r2d2: r2d2, c3po: c3po} do
      game = Game.new()
      {:ok, game} = Game.join(game, bender)
      {:ok, game} = Game.join(game, r2d2)
      {:ok, game} = Game.join(game, c3po)
      assert [bender, r2d2, c3po] == Game.robots(game)
    end
  end

  describe "admin?/2" do
    test "is robot an admin", %{bender: bender, r2d2: r2d2} do
      game = Game.new()
      {:ok, game} = Game.join(game, bender)
      {:ok, game} = Game.join(game, r2d2)
      assert Game.admin?(game, bender.id)
      refute Game.admin?(game, r2d2.id)
    end
  end

  describe "score_point/2" do
    test "only scores point in playing state", %{bender: bender} do
      game = Game.new()
      {:ok, %Game{state: :setup} = game} = Game.join(game, bender)
      game = Game.score_point(game, bender.id)
      assert [%Robot{score: 0}] = Game.robots(game)
    end

    test "scores points and transitions to finished", %{bender: bender} do
      game = Game.new(%GameConfig{winning_score: 1})
      {:ok, game} = Game.join(game, bender)
      game = Game.play(game)
      assert %Game{state: :finished} = game = Game.score_point(game, bender.id)
      assert [%Robot{score: 1}] = Game.robots(game)
    end
  end

  describe "score_board/1" do
    test "returns robots in descending order by score", %{bender: bender, r2d2: r2d2, c3po: c3po} do
      game = Game.new()
      {:ok, game} = Game.join(game, bender)
      {:ok, game} = Game.join(game, r2d2)
      {:ok, game} = Game.join(game, c3po)

      game =
        game
        |> Game.play()
        |> Game.score_point(r2d2.id)
        |> Game.score_point(bender.id)
        |> Game.score_point(r2d2.id)

      assert [
               %Robot{name: "R2-D2", score: 2},
               %Robot{name: "Bender", score: 1},
               %Robot{name: "C-3PO", score: 0}
             ] = Game.score_board(game)
    end
  end

  describe "play_again/1" do
    test "resets game back to config", %{bender: bender} do
      game = Game.new(%GameConfig{winning_score: 1, countdown: 2})
      {:ok, game} = Game.join(game, bender)

      assert %Game{countdown: 0, state: :finished} =
               game =
               game
               |> Game.countdown()
               |> Game.countdown()
               |> Game.countdown()
               |> Game.play()
               |> Game.score_point(bender.id)

      assert [%Robot{score: 1}] = Game.robots(game)

      assert %Game{countdown: 2, state: :setup} = game = Game.play_again(game)
      assert [%Robot{score: 0}] = Game.robots(game)
    end
  end
end

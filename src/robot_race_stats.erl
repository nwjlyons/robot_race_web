-module(robot_race_stats).

-export([new/0]).

new() ->
    #{
        '__struct__' => 'Elixir.RobotRace.Stats',
        num_games => 0
    }.

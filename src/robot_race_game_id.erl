-module(robot_race_game_id).

-export([new/0]).

new() ->
    <<"g_", (robot_race_id:new())/binary>>.

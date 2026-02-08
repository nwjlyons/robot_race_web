-module(robot_race_robot_id).

-export([new/0]).

new() ->
    <<"r_", (robot_race_id:new())/binary>>.

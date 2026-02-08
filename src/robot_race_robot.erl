-module(robot_race_robot).

-export([new/2]).

new(Name, Role) when is_binary(Name), (Role =:= guest orelse Role =:= admin) ->
    #{
        '__struct__' => 'Elixir.RobotRace.Robot',
        id => robot_race_robot_id:new(),
        name => Name,
        role => Role,
        score => 0
    }.

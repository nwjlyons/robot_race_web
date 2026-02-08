-module(robot_race_game).

-export([
    new/0,
    new/1,
    join/2,
    score_point/2,
    robots/1,
    admin/2,
    play/1,
    countdown/1,
    score_board/1,
    winner/1,
    play_again/1,
    leaderboard/1
]).

new() ->
    new('Elixir.RobotRace.GameConfig':'__struct__'()).

new(Config) ->
    #{
        '__struct__' => 'Elixir.RobotRace.Game',
        id => robot_race_game_id:new(),
        winning_score => maps:get(winning_score, Config),
        num_robots => maps:get(num_robots, Config),
        countdown => maps:get(countdown, Config),
        config => Config,
        robots => [],
        state => setup,
        previous_wins => #{}
    }.

join(#{state := State}, _Robot) when State =:= counting_down; State =:= playing; State =:= finished ->
    {error, game_in_progress};
join(Game, Robot) ->
    Robots = maps:get(robots, Game),
    NumRobots = maps:get(num_robots, Game),
    MaxRobots = maps:get(last, NumRobots),
    case length(Robots) >= MaxRobots of
        true ->
            {error, game_full};
        false ->
            {ok, Game#{robots := Robots ++ [Robot]}}
    end.

score_point(#{state := playing} = Game, RobotId) ->
    Robots = maps:get(robots, Game),
    UpdatedRobots = [score_if_match(Robot, RobotId) || Robot <- Robots],
    UpdatedGame = Game#{robots := UpdatedRobots},
    case find_robot(UpdatedRobots, RobotId) of
        undefined ->
            UpdatedGame;
        UpdatedRobot ->
            case maps:get(score, UpdatedRobot) >= maps:get(winning_score, UpdatedGame) of
                true -> UpdatedGame#{state := finished};
                false -> UpdatedGame
            end
    end;
score_point(Game, _RobotId) ->
    Game.

robots(Game) ->
    maps:get(robots, Game).

admin(Game, RobotId) ->
    case find_robot(maps:get(robots, Game), RobotId) of
        undefined ->
            erlang:error({badkey, RobotId});
        Robot ->
            maps:get(role, Robot) =:= admin
    end.

play(Game) ->
    Game#{state := playing}.

countdown(#{state := setup} = Game) ->
    Game#{state := counting_down};
countdown(Game) ->
    Countdown = maps:get(countdown, Game),
    case Countdown > 0 of
        true ->
            Game#{state := counting_down, countdown := Countdown - 1};
        false ->
            Game#{state := playing}
    end.

score_board(Game) ->
    Robots = maps:get(robots, Game),
    Indexed = lists:zip(lists:seq(1, length(Robots)), Robots),
    Sorted = lists:sort(fun compare_robot_score/2, Indexed),
    [Robot || {_Index, Robot} <- Sorted].

winner(Game) ->
    hd(score_board(Game)).

play_again(Game) ->
    Config = maps:get(config, Game),
    Game#{
        winning_score := maps:get(winning_score, Config),
        num_robots := maps:get(num_robots, Config),
        countdown := maps:get(countdown, Config),
        robots := reset_robot_scores(maps:get(robots, Game)),
        state := setup,
        previous_wins := save_winner(Game)
    }.

leaderboard(Game) ->
    CurrentWinnerId = maps:get(id, winner(Game)),
    PreviousWins = maps:get(previous_wins, Game),
    RobotsWithWins = [
        {Robot, score_with_previous_wins(Robot, CurrentWinnerId, PreviousWins)}
        || Robot <- robots(Game)
    ],
    Indexed = lists:zip(lists:seq(1, length(RobotsWithWins)), RobotsWithWins),
    Sorted = lists:sort(fun compare_leaderboard_score/2, Indexed),
    [Entry || {_Index, Entry} <- Sorted].

score_if_match(Robot, RobotId) ->
    case maps:get(id, Robot) of
        RobotId ->
            Robot#{score := maps:get(score, Robot) + 1};
        _Other ->
            Robot
    end.

find_robot([], _RobotId) ->
    undefined;
find_robot([Robot | Rest], RobotId) ->
    case maps:get(id, Robot) of
        RobotId -> Robot;
        _Other -> find_robot(Rest, RobotId)
    end.

compare_robot_score({IndexA, RobotA}, {IndexB, RobotB}) ->
    ScoreA = maps:get(score, RobotA),
    ScoreB = maps:get(score, RobotB),
    case ScoreA =:= ScoreB of
        true -> IndexA =< IndexB;
        false -> ScoreA > ScoreB
    end.

compare_leaderboard_score({IndexA, {_RobotA, ScoreA}}, {IndexB, {_RobotB, ScoreB}}) ->
    case ScoreA =:= ScoreB of
        true -> IndexA =< IndexB;
        false -> ScoreA > ScoreB
    end.

reset_robot_scores(Robots) ->
    [Robot#{score := 0} || Robot <- Robots].

save_winner(Game) ->
    WinnerId = maps:get(id, winner(Game)),
    PreviousWins = maps:get(previous_wins, Game),
    CurrentScore = maps:get(WinnerId, PreviousWins, 0),
    PreviousWins#{WinnerId => CurrentScore + 1}.

score_with_previous_wins(Robot, CurrentWinnerId, PreviousWins) ->
    RobotId = maps:get(id, Robot),
    PreviousWinCount = maps:get(RobotId, PreviousWins, 0),
    case CurrentWinnerId =:= RobotId of
        true -> PreviousWinCount + 1;
        false -> PreviousWinCount
    end.

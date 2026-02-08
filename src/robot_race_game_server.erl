-module(robot_race_game_server).
-behaviour(gen_server).

-export([
    start_link/1,
    exists/1,
    get/1,
    join/2,
    countdown/1,
    score_point/2,
    play_again/1,
    subscribe/1
]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(TIMEOUT_MS, 10 * 60 * 1000).

start_link(Game) ->
    GameId = maps:get(id, Game),
    gen_server:start_link({global, GameId}, ?MODULE, Game, []).

exists(GameId) when is_binary(GameId) ->
    case global:whereis_name(GameId) of
        Pid when is_pid(Pid) -> true;
        undefined -> false
    end;
exists(_GameId) ->
    false.

get(GameId) ->
    gen_server:call(via_tuple(GameId), get).

join(GameId, Robot) ->
    gen_server:call(via_tuple(GameId), {join, Robot}).

countdown(GameId) ->
    gen_server:call(via_tuple(GameId), countdown).

score_point(GameId, RobotId) ->
    gen_server:call(via_tuple(GameId), {score_point, RobotId}).

play_again(GameId) ->
    gen_server:call(via_tuple(GameId), play_again).

subscribe(Game) ->
    Topic = game_topic(maps:get(id, Game)),
    'Elixir.Phoenix.PubSub':subscribe('Elixir.RobotRaceWeb.PubSub', Topic).

init(Game) ->
    process_flag(trap_exit, true),
    robot_race_stats_server:increment_num_games(),
    {ok, Game, ?TIMEOUT_MS}.

handle_call(get, _From, Game) ->
    {reply, Game, Game, ?TIMEOUT_MS};
handle_call({join, Robot}, _From, Game) ->
    case robot_race_game:join(Game, Robot) of
        {ok, UpdatedGame} ->
            broadcast(UpdatedGame),
            {reply, {ok, UpdatedGame}, UpdatedGame, ?TIMEOUT_MS};
        Error ->
            {reply, Error, Game, ?TIMEOUT_MS}
    end;
handle_call(countdown, _From, Game) ->
    UpdatedGame = robot_race_game:countdown(Game),
    schedule_countdown(1000),
    broadcast(UpdatedGame),
    {reply, UpdatedGame, UpdatedGame, ?TIMEOUT_MS};
handle_call({score_point, RobotId}, _From, Game) ->
    UpdatedGame = robot_race_game:score_point(Game, RobotId),
    broadcast(UpdatedGame),
    {reply, UpdatedGame, UpdatedGame, ?TIMEOUT_MS};
handle_call(play_again, _From, Game) ->
    UpdatedGame = robot_race_game:play_again(Game),
    broadcast(UpdatedGame),
    {reply, UpdatedGame, UpdatedGame, ?TIMEOUT_MS};
handle_call(_Request, _From, Game) ->
    {reply, nil, Game, ?TIMEOUT_MS}.

handle_cast(_Request, State) ->
    {noreply, State, ?TIMEOUT_MS}.

handle_info(countdown, Game) ->
    UpdatedGame = robot_race_game:countdown(Game),
    case UpdatedGame of
        #{state := counting_down, countdown := Countdown} when Countdown > 0 ->
            schedule_countdown(1000);
        #{state := counting_down} ->
            schedule_countdown(200);
        _Other ->
            ok
    end,
    broadcast(UpdatedGame),
    {noreply, UpdatedGame, ?TIMEOUT_MS};
handle_info(timeout, State) ->
    {stop, normal, State};
handle_info({'EXIT', _Pid, Reason}, State) ->
    {stop, Reason, State};
handle_info(_Msg, State) ->
    {noreply, State, ?TIMEOUT_MS}.

terminate(normal, Game) ->
    'Elixir.RobotRaceWeb.Endpoint':broadcast(game_topic(maps:get(id, Game)), <<"terminate">>, nil),
    ok;
terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

broadcast(Game) ->
    'Elixir.RobotRaceWeb.Endpoint':broadcast(
        game_topic(maps:get(id, Game)),
        <<"update">>,
        #{game => Game}
    ).

game_topic(GameId) ->
    <<"game:", GameId/binary>>.

via_tuple(GameId) ->
    {global, GameId}.

schedule_countdown(TimeMs) when is_integer(TimeMs) ->
    erlang:send_after(TimeMs, self(), countdown).

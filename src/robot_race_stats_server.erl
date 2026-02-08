-module(robot_race_stats_server).
-behaviour(gen_server).

-export([start_link/0, start_link/1, get/0, increment_num_games/0, subscribe/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(EVENT, <<"stats">>).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

start_link(_Opts) ->
    start_link().

init([]) ->
    {ok, robot_race_stats:new()}.

get() ->
    gen_server:call(?MODULE, get).

increment_num_games() ->
    gen_server:call(?MODULE, increment_num_games).

subscribe() ->
    'Elixir.Phoenix.PubSub':subscribe('Elixir.RobotRaceWeb.PubSub', ?EVENT).

handle_call(increment_num_games, _From, Stats) ->
    NewStats = Stats#{num_games := maps:get(num_games, Stats) + 1},
    broadcast(NewStats),
    {reply, NewStats, NewStats};
handle_call(get, _From, Stats) ->
    {reply, Stats, Stats};
handle_call(_Request, _From, Stats) ->
    {reply, nil, Stats}.

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(_Msg, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

broadcast(Stats) ->
    'Elixir.RobotRaceWeb.Endpoint':broadcast(?EVENT, <<"update">>, #{stats => Stats}).

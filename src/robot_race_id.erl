-module(robot_race_id).

-export([new/0]).

-define(SIZE, 5).
-define(ALPHABET, <<"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz">>).
-define(ALPHABET_SIZE, 62).

new() ->
    Bytes = crypto:strong_rand_bytes(?SIZE),
    Encoded = [binary:at(?ALPHABET, Byte rem ?ALPHABET_SIZE) || <<Byte:8>> <= Bytes],
    list_to_binary(Encoded).

defmodule RobotRace.ZigDomain do
  @moduledoc false

  use Zig, otp_app: :robot_race_web, zig_code_path: "./priv/zig/robot_race_domain.zig"

  @spec call(atom() | String.t(), map()) :: term()
  def call(function, args \\ %{})
      when (is_atom(function) or is_binary(function)) and is_map(args) do
    call_nif(to_string(function), args)
  end
end

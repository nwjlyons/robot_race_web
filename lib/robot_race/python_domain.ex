defmodule RobotRace.PythonDomain do
  @moduledoc false

  @python_dir Path.expand("../../priv/python", __DIR__)

  @spec call(atom() | String.t(), map()) :: term()
  def call(function, args \\ %{})
      when (is_atom(function) or is_binary(function)) and is_map(args) do
    function_name = to_string(function)

    {result, _globals} =
      Pythonx.eval(
        """
        import sys

        def normalize(value):
            if isinstance(value, bytes):
                return value.decode("utf-8")

            if isinstance(value, dict):
                return {normalize(key): normalize(item) for key, item in value.items()}

            if isinstance(value, list):
                return [normalize(item) for item in value]

            if isinstance(value, tuple):
                return tuple(normalize(item) for item in value)

            return value

        normalized_python_dir = normalize(python_dir)
        normalized_function_name = normalize(function_name)
        normalized_args = normalize(args)

        if normalized_python_dir not in sys.path:
            sys.path.append(normalized_python_dir)

        import robot_race_domain as domain

        getattr(domain, normalized_function_name)(normalized_args)
        """,
        %{
          "python_dir" => @python_dir,
          "function_name" => function_name,
          "args" => args
        }
      )

    Pythonx.decode(result)
  end
end

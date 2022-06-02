defmodule RobotRaceWeb.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: RobotRaceWeb.DynamicSupervisor},
      RobotRaceWeb.Endpoint,
      {Phoenix.PubSub, name: RobotRaceWeb.PubSub}
    ]

    opts = [strategy: :one_for_one, name: RobotRaceWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

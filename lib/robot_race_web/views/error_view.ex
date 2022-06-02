defmodule RobotRaceWeb.ErrorView do
  use RobotRaceWeb, :view

  def template_not_found(template, _assigns) do
    error = Phoenix.Controller.status_message_from_template(template)
    Phoenix.View.render(__MODULE__, "error.html", error: error)
  end
end

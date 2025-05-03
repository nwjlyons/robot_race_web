defmodule RobotRaceWeb.ErrorHelpers do
  @moduledoc false

  import Phoenix.HTML.Form
  use PhoenixHTMLHelpers

  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:div, format_error(error),
        class: "invalid-feedback font-mono text-red mb-2 text-center text-xs sm:text-base",
        phx_feedback_for: input_name(form, field)
      )
    end)
  end

  defp format_error({msg, opts}) do
    Regex.replace(~r"%{(\w+)}", msg, fn _captures, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end
end

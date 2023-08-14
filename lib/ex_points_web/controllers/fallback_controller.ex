defmodule ExPointsWeb.FallbackController do
  use Phoenix.Controller

  alias Plug.Conn
  alias OpenApiSpex.OpenApi

  def call(conn, {:error, %{errors: errors}}) do
    json = OpenApi.json_encoder().encode!(%{errors: render_errors(errors)})

    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(422, json)
  end

  def call(conn, {:error, reason}) do
    json = OpenApi.json_encoder().encode!(%{errors: %{internal_server_error: inspect(reason)}})

    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(422, json)
  end

  defp render_errors(%Ecto.Changeset{valid?: false} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {_, error} ->
      error[:validation]
    end)
  end

  defp render_errors(errors) do
    alias OpenApiSpex.Cast.Error

    for error <- errors, into: %{} do
      {Error.path_to_string(error), [error.reason]}
    end
  end
end

defmodule ExPointsWeb.FallbackController do
  use Phoenix.Controller

  alias Plug.Conn
  alias OpenApiSpex.OpenApi


  def call(conn, {:error, %{errors: errors}}) do
    response = %{
      errors: Enum.map(errors, fn {k, error} ->
        "#{k} #{ExPointsWeb.ErrorHelpers.translate_error(error)}"
      end)
    }

    json = OpenApi.json_encoder().encode!(response)

    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(422, json)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(ExPointsWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:forbidden)
    |> put_view(ExPointsWeb.ErrorView)
    |> render(:"403")
  end
end

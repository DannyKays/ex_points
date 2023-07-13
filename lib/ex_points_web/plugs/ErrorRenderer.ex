defmodule ExPointsWeb.Plugs.ErrorRenderer do
  @behaviour Plug

  alias Plug.Conn
  alias OpenApiSpex.OpenApi

  @impl Plug
  def init(errors), do: errors

  @impl Plug
  def call(conn, errors) when is_list(errors) do
    response = %{
      errors: Enum.map(errors, &to_string/1)
    }

    json = OpenApi.json_encoder().encode!(response)

    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(422, json)
  end
end

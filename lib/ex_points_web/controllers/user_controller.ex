defmodule ExPointsWeb.UserController do
  use ExPointsWeb, :controller

  alias ExPoints.Workers.UserPoints

  def index(conn, _params) do
    {:ok, users, timestamp} = UserPoints.get_users()
    render(conn, "index.json", users: users, timestamp: timestamp)
  end
end

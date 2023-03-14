defmodule ExPointsWeb.UserControllerTest do
  use ExPointsWeb.ConnCase

  describe "Users index/2" do
    alias ExPoints.Workers.UserPoints

    test "GET /", %{conn: conn} do
      conn = get(conn, "/")
      {:ok, users, _timestamp} = UserPoints.get_users()

      assert json_response(conn, 200) == %{
               "timestamp" => nil,
               "users" => Enum.map(users, &Map.take(&1, [:id, :points]))
             }
    end
  end
end

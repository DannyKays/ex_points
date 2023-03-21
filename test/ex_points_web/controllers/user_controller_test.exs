defmodule ExPointsWeb.UserControllerTest do
  use ExPointsWeb.ConnCase

  describe "Users index/2" do
    alias ExPoints.Workers.UserPoints
    alias ExPointsWeb.UserView

    setup do
      child_spec = %{
        id: UserPointsTest,
        start: {UserPoints, :start_link, [[], [name: UserPointsTest]]}
      }

      pid = start_supervised!(child_spec)
      [pid: pid]
    end

    test "GET /", %{conn: conn, pid: pid} do
      conn = get(conn, "/")
      {:ok, users, timestamp} = UserPoints.get_users(pid)
      user_points_resp = UserView.render("index.json", %{timestamp: timestamp, users: users})
      assert json_response(conn, 200) == user_points_resp
    end
  end
end

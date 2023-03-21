defmodule ExPointsWeb.UserViewTest do
  use ExPointsWeb.ConnCase, async: true
  import Phoenix.View
  alias ExPoints.AccountsFixtures

  test "index.json renders list of users" do
    user = AccountsFixtures.user_fixture()

    assert render(ExPointsWeb.UserView, "index.json", users: [user], timestamp: nil) == %{
             "timestamp" => nil,
             "users" => [%{"id" => user.id, "points" => user.points}]
           }
  end
end

defmodule ExPointsWeb.UserView do
  use ExPointsWeb, :view

  def render("index.json", %{users: users, timestamp: timestamp}) do
    timestamp = if timestamp, do: NaiveDateTime.to_string(timestamp)

    %{
      timestamp: timestamp,
      users: render_many(users, __MODULE__, "user.json")
    }
  end

  def render("user.json", %{user: user}) do
    %{id: user.id, points: user.points}
  end
end

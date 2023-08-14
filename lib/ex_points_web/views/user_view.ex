defmodule ExPointsWeb.UserView do
  use ExPointsWeb, :view

  def render("index.json", %{users: users, timestamp: timestamp}) do
    timestamp = if timestamp, do: NaiveDateTime.to_string(timestamp)

    %{
      "timestamp" => timestamp,
      "users" => render_many(users, __MODULE__, "show.json")
    }
  end

  def render("show.json", %{user: user}) do
    %{"id" => user.id, "points" => user.points}
  end

  def render("image.json", %{image: image}) do
    %{
      "name" => image.name,
      "mime_type" => image.mime_type,
      "google_drive_id" => image.google_drive_id
    }
  end
end

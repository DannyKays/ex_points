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

  def render("folder.json", %{folder: folder, sub_folders: sub_folders}) do
    %{
      "folder" => Map.take(folder, [:id, :name, :mimeType]),
      "sub_folders" => render_many(sub_folders, __MODULE__, "sub_folder.json", as: :folder)
    }
  end

  def render("sub_folder.json", %{folder: folder}) do
    folder
  end

  def render("drive_file.json", %{file: file}) do
    %{name: file.name, mime_type: file.mimeType}
  end
end

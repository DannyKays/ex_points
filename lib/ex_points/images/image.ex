defmodule ExPoints.Images.Image do
  use Ecto.Schema
  import Ecto.Changeset

  schema "images" do
    field :name, :string
    field :mime_type, :string
    field :google_drive_id, :string

    timestamps()
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:name, :mime_type, :google_drive_id])
    |> validate_required([:name, :mime_type])
  end
end

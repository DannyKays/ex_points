defmodule ExPoints.Repo.Migrations.ImagesAddGoogleDriveId do
  use Ecto.Migration

  def up do
    alter table(:images) do
      add :google_drive_id, :string
    end
  end

  def down do
    alter table(:images) do
      remove :google_drive_id
    end
  end
end

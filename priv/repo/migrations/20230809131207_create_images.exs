defmodule ExPoints.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :name, :string
      add :mime_type, :string

      timestamps()
    end
  end
end

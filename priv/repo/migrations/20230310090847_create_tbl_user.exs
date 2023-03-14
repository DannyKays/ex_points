defmodule ExPoints.Repo.Migrations.CreateTblUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :points, :integer, default: 0

      timestamps()
    end

    create index(:users, [:points])
  end
end

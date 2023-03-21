defmodule ExPoints.Repo.Migrations.AddUserPointsCheckContraint do
  use Ecto.Migration

  def up do
    create constraint("users", :user_points_range, check: "points between 0 and 100")
  end

  def down do
    drop constraint("users", "user_points_range")
  end
end

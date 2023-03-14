defmodule ExPoints.Repo.Migrations.CreateRandomPoints_UDF do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION random_points(min_points INT, max_points INT)
      RETURNS INT AS
    $$
    BEGIN
      RETURN floor(random()* (max_points - min_points + 1) + min_points);
    END;
    $$ language 'plpgsql' STRICT;
    """
  end

  def down do
    execute "DROP FUNCTION IF EXISTS random_points"
  end
end

defmodule ExPoints.Repo.Migrations.CreateUpdatePointsResetTrigger do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION reset_exceeding_points()
      RETURNS TRIGGER
      LANGUAGE PLPGSQL
      AS
    $$
    BEGIN
      IF NEW.points > 100 THEN
        NEW.points := OLD.points;
      END IF;
      RETURN NEW;
    END;
    $$
    """

    flush()

    execute """
    CREATE TRIGGER reset_user_points
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE PROCEDURE reset_exceeding_points();
    """
  end

  def down do
    execute """
    DROP TRIGGER reset_user_points
    ON users;
    """

    flush()

    execute "DROP FUNCTION IF EXISTS reset_exceeding_points"
  end
end

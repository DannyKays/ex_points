defmodule ExPoints.Repo do
  use Ecto.Repo,
    otp_app: :ex_points,
    adapter: Ecto.Adapters.Postgres
end

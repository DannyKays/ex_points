defmodule ExPoints.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :points, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:points])
    |> validate_required([:points])
    |> validate_number(:points,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100,
      message: " should be 0 - 100"
    )
  end
end

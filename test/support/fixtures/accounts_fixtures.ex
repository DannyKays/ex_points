defmodule ExPoints.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExPoints.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{})
      |> ExPoints.Accounts.create_user()

    user
  end
end

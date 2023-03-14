defmodule ExPoints.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias ExPoints.Repo

  alias ExPoints.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a list of at most `max_users` with more points than `min_number`.

  ## Examples

      iex> list_users(min_number)
      [%User{}, ...]

  """
  def list_users(min_number, max_users) do
    User
    |> where([u], u.points > ^min_number)
    |> limit(^max_users)
    |> select([u], u)
    |> Repo.all()
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Updates each user's points using a database UDF `random_points` as random number generator.

  """
  def update_points(min_points, max_points) do
    User
    |> where([u], u.points < ^max_points)
    |> update(
      set: [updated_at: ^timestamp()],
      inc: [points: fragment("random_points(?, ?)", ^min_points, ^max_points)]
    )
    |> Repo.update_all([])
  end

  @doc """
  Generates and inserts 1,000,000 user seeds.

  """
  def load_users do
    "user"
    |> with_cte("user", as: fragment("select  0 as points FROM generate_series(1, 1000000)"))
    |> from(as: :user)
    |> select(
      [user: u],
      %{
        points: u.points,
        inserted_at: fragment("timezone('utc', now())::timestamp(0)"),
        updated_at: fragment("timezone('utc', now())::timestamp(0)")
      }
    )
    |> then(&Repo.insert_all(User, &1))
  end

  @doc """
  Returns the current UTC datetime with the microsecond field truncated to seconds

  """
  def timestamp do
    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end
end

defmodule ExPointsWeb.UserController do
  use ExPointsWeb, :controller

  alias ExPoints.Workers.UserPoints

  alias OpenApiSpex.Operation

  alias ExPoints.Schemas

  alias ExPoints.Accounts

  alias OpenApiSpex.Schema

  plug OpenApiSpex.Plug.CastAndValidate, render_error: ExPointsWeb.Plugs.ErrorRenderer

  action_fallback ExPointsWeb.FallbackController

  @spec open_api_operation(any) :: Operation.t
  def open_api_operation(action) do
    operation = String.to_existing_atom("#{action}_operation")
    apply(__MODULE__, operation, [])
  end

  @spec index_operation() :: Operation.t
  def index_operation() do
    %Operation{
      tags: ["users", "List users"],
      summary: "List users",
      description: "List users with points above min-points",
      operationId: "UserController.index",
      parameters: [],
      responses: %{
        200 => Operation.response("User", "application/json", Schemas.UserListResponse)
      }
    }
  end

  def index(conn, _params) do
    {:ok, users, timestamp} = UserPoints.get_users()
    render(conn, "index.json", users: users, timestamp: timestamp)
  end

  @spec index_operation() :: Operation.t
  def create_operation() do
    %Operation{
      tags: ["users"],
      summary: "Create user",
      description: "Create a user",
      operationId: "UserController.create",
      parameters: [],
      requestBody:
      Operation.request_body("The user attributes", "application/json", Schemas.UserRequest,
          required: true
        ),
      responses: %{
        201 => Operation.response("User", "application/json", Schemas.UserResponse),
        422 => OpenApiSpex.JsonErrorResponse.response()
      }
    }
  end

  def create(conn = %{body_params: %Schemas.UserRequest{user: user_params}}, _params) do
    with {:ok, %Accounts.User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_path(conn, :show, user))
      |> render("show.json", user: user)
    end
  end

  @doc """
  API Spec for :show action
  """
  def show_operation() do
    %Operation{
      tags: ["users"],
      summary: "Show user",
      description: "Show a user by ID",
      operationId: "UserController.show",
      parameters: [
        Operation.parameter(:id, :path, %Schema{type: :integer, minimum: 1}, "User ID", example: 123, required: true)
      ],
      responses: %{
        200 => Operation.response("User", "application/json", Schemas.UserResponse)
      }
    }
  end

  def show(conn, %{id: id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end
end

# Example on operation.parameter

# parameters: [
#   id: [
#     in: :path,
#     # `:type` can be an atom, %Schema{}, or %Reference{}
#     type: %Schema{type: :integer, minimum: 1},
#     description: "User ID",
#     example: 123,
#     required: true
#   ]
# ],

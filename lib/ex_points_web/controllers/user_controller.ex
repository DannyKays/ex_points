defmodule ExPointsWeb.UserController do
  use ExPointsWeb, :controller

  alias ExPoints.Workers.UserPoints

  alias OpenApiSpex.Operation

  alias ExPoints.Schemas

  alias ExPoints.{Accounts, Images}

  alias OpenApiSpex.Schema

  plug OpenApiSpex.Plug.CastAndValidate, render_error: ExPointsWeb.Plugs.ErrorRenderer

  action_fallback ExPointsWeb.FallbackController

  @gdrive_upload_folder "ExPoints"

  @spec open_api_operation(any) :: Operation.t()
  def open_api_operation(action) do
    operation = String.to_existing_atom("#{action}_operation")
    apply(__MODULE__, operation, [])
  end

  @spec index_operation() :: Operation.t()
  def index_operation() do
    %Operation{
      tags: ["users"],
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

  @spec index_operation() :: Operation.t()
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
        Operation.parameter(:id, :path, %Schema{type: :integer, minimum: 1}, "User ID",
          example: 123,
          required: true
        )
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

  @spec upload_image_operation() :: Operation.t()
  def upload_image_operation() do
    %Operation{
      tags: ["users", "images"],
      summary: "Image upload",
      description: "Upload an image",
      operationId: "UserController.upload_image",
      parameters: [],
      requestBody:
        Operation.request_body(
          "Image upload attributes",
          "multipart/form-data",
          Schemas.ImageRequest,
          required: true
        ),
      responses: %{
        201 => Operation.response("Image", "application/json", Schemas.ImageResponse),
        422 => OpenApiSpex.JsonErrorResponse.response()
      }
    }
  end

  def upload_image(
        conn = %{body_params: %Schemas.ImageRequest{file: _file} = image_params},
        _params
      ) do
    with {:ok, %GoogleApi.Drive.V3.Model.File{id: _id} = file} <-
           upload_to_google_drive(image_params),
         image_attrs <- build_image_attrs(file),
         {:ok, %Images.Image{} = image} <- Images.create_image(image_attrs) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_path(conn, :show_image, image))
      |> render("image.json", image: image)
    end
  end

  @doc """
  API Spec for :show image action
  """
  def show_image_operation() do
    %Operation{
      tags: ["users", "images"],
      summary: "Show image",
      description: "Show an image by ID",
      operationId: "UserController.show_image",
      parameters: [
        Operation.parameter(:id, :path, %Schema{type: :integer, minimum: 1}, "Image ID",
          example: 123,
          required: true
        )
      ],
      responses: %{
        200 => Operation.response("ShowImage", "application/json", Schemas.ImageResponse)
      }
    }
  end

  def show_image(conn, %{id: id}) do
    image = Images.get_image!(id)
    render(conn, "image.json", image: image)
  end

  defp upload_to_google_drive(%{file: %Plug.Upload{path: path} = upload} = params) do
    with {:ok, %Goth.Token{token: token}} <- Goth.fetch(ExPoints.Goth),
         conn = GoogleApi.Drive.V3.Connection.new(token),
         {:ok, folder_structure} <- get_upload_folder(conn, params) do
      file_meta = build_file_meta(upload, folder_structure)
      GoogleApi.Drive.V3.Api.Files.drive_files_create_simple(conn, "multipart", file_meta, path)
    end
  end

  defp build_file_meta(%Plug.Upload{filename: name} = upload, folder_id) do
    parent_folder_ids = List.wrap(folder_id)
    uuid = Ecto.UUID.generate()
    filename = "#{uuid}-#{name}"

    %GoogleApi.Drive.V3.Model.File{
      name: filename,
      parents: parent_folder_ids,
      mimeType: upload.content_type
    }
  end

  defp build_file_meta(params, folder_id) do
    parent_folder_ids = List.wrap(folder_id)

    %GoogleApi.Drive.V3.Model.File{
      name: params.upload_folder,
      parents: parent_folder_ids,
      mimeType: "application/vnd.google-apps.folder"
    }
  end

  defp build_image_attrs(gdrive_file) do
    %{google_drive_id: gdrive_file.id, name: gdrive_file.name, mime_type: gdrive_file.mimeType}
  end

  defp create_folder(_conn, folder, root_folders) when folder in [".", "/"],
    do: {:ok, root_folders}

  defp create_folder(conn, folder, root_folders) do
    file_meta = build_file_meta(%{upload_folder: folder}, root_folders)
    params = [body: file_meta]

    with {:error, _reason} <- get_object(conn, folder),
         {:ok, file} <- GoogleApi.Drive.V3.Api.Files.drive_files_create(conn, params) do
      {:ok, file}
    end
  end

  defp get_upload_folder(conn, params) do
    case get_object(conn, @gdrive_upload_folder) do
      {:ok, %{id: root_folder_id}} ->
        params.upload_folder
        |> folder_structure()
        |> Enum.reduce_while({:ok, [root_folder_id]}, fn folder, {_, folders} ->
          case create_folder(conn, folder, folders) do
            {:ok, [folder_id]} -> {:cont, {:ok, [folder_id]}}
            {:ok, folder} -> {:cont, {:ok, [folder.id]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_object(conn, object_name, opts \\ []) do
    query = "name = '#{object_name}'"
    opts = Keyword.merge([q: query], opts)

    case GoogleApi.Drive.V3.Api.Files.drive_files_list(conn, opts) do
      {:ok, %{files: [file]}} ->
        {:ok, file}

      {:ok, %{files: [_ | _]}} ->
        {:error, :multiple_files_found}

      {:ok, %{files: []}} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}

      _unhandled_result ->
        {:error, :invalid_result}
    end
  end

  defp folder_structure(nil), do: []

  defp folder_structure(upload_path) do
    upload_path
    |> Path.dirname()
    |> Path.split()
  end
end

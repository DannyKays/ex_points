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

  @doc """
  API Spec for :delete image action
  """
  def delete_image_operation() do
    %Operation{
      tags: ["users", "images"],
      summary: "Delete image",
      description: "Delete an image by ID",
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

  def delete_image(conn, %{id: id}) do
    image = Images.get_image!(id)
    with {:ok, image} <- Images.delete_image(image),
         {:ok, %Goth.Token{token: token}} <- Goth.fetch(ExPoints.Goth),
         drive_conn = GoogleApi.Drive.V3.Connection.new(token),
         {:ok, drive_image} <- get_object(drive_conn, image.name),
         {:ok, _resp} <- GoogleApi.Drive.V3.Api.Files.drive_files_delete(drive_conn, drive_image.id <> "test") do
      render(conn, "image.json", image: image)
    end
  end

  @doc """
  API Spec for :load folders action
  """
  def show_folder_operation() do
    %Operation{
      tags: ["users", "folders"],
      summary: "Show folder",
      description: "View a folder by name",
      operationId: "UserController.show_folder",
      parameters: [
        Operation.parameter(:folder, :path, %Schema{type: :string}, "folder name",
          example: "some-drive-folder",
          required: true
        )
      ],
      responses: %{
        200 => Operation.response("ShowFolder", "application/json", Schemas.FolderResponse)
      }
    }
  end

  def show_folder(conn, %{folder: folder_name}) do
    params = [
      includeItemsFromAllDrives: true,
      supportsAllDrives: true,
      corpora: "allDrives"
    ]

    with {:ok, %Goth.Token{token: token}} <- Goth.fetch(ExPoints.Goth),
         drive_conn = GoogleApi.Drive.V3.Connection.new(token),
         {:ok, drive_folder} <- get_object(drive_conn, folder_name, params),
         {:ok, files} <- list_files(drive_conn, drive_folder.id, params) do

      path = Application.app_dir(:ex_points, "/priv/inter_company_invoicing_drive_mappings.csv")
      sub_folders =
        files
        |> Enum.filter(&(&1.mimeType == "application/vnd.google-apps.folder"))
        |> Enum.reduce([], fn object, folders ->
          [%{remote_entity_name: object.name, drive_folder: object.name} | folders]
        end)
        |> tap(fn sub_folders ->
          content = CSV.encode(sub_folders, headers: true) |> Enum.to_list
          File.write(path, content)
        end)

      render(conn, "folder.json", folder: drive_folder, sub_folders: sub_folders)
    end
  end

  @doc """
  API Spec for :create app config files action
  """
  def create_app_config_operation() do
    %Operation{
      tags: ["users", "config-files"],
      summary: "Application configuration file in drive",
      description: "Upload a configuaration file",
      operationId: "UserController.create_app_config",
      parameters: [],
      requestBody:
        Operation.request_body(
          "App config upload attributes",
          "multipart/form-data",
          Schemas.AppConfigUploadRequest,
          required: true
        ),
      responses: %{
        201 => Operation.response("AppConfig", "application/json", Schemas.DriveFileResponse),
        422 => OpenApiSpex.JsonErrorResponse.response()
      }
    }
  end

  def create_app_config(
        conn = %{body_params: %Schemas.AppConfigUploadRequest{file: _file} = app_config_params},
        _params
      ) do
    params = [
      includeItemsFromAllDrives: true,
      supportsAllDrives: true,
      corpora: "allDrives"
    ]
    with {:ok, %GoogleApi.Drive.V3.Model.File{id: _id} = file} <- upload_to_google_drive(app_config_params, params) do
      conn
      |> put_status(:created)
      |> render("drive_file.json", file: file)
    end
  end

  @doc """
  API Spec for :create app config files action
  """
  def update_app_config_operation() do
    %Operation{
      tags: ["users", "config-files"],
      summary: "Application configuration file in drive",
      description: "Update a configuaration file",
      operationId: "UserController.update_app_config",
      parameters: [],
      requestBody:
        Operation.request_body(
          "App config update attributes",
          "multipart/form-data",
          Schemas.AppConfigUploadRequest,
          required: true
        ),
      responses: %{
        201 => Operation.response("AppConfig", "application/json", Schemas.DriveFileResponse),
        422 => OpenApiSpex.JsonErrorResponse.response()
      }
    }
  end

  def update_app_config(
        conn = %{body_params: %Schemas.AppConfigUploadRequest{file: _file} = app_config_params},
        _params
      ) do
    params = [
      includeItemsFromAllDrives: true,
      supportsAllDrives: true,
      corpora: "allDrives"
    ]
    with {:ok, %GoogleApi.Drive.V3.Model.File{id: _id} = file} <- upload_to_google_drive(app_config_params, params) do
      conn
      |> put_status(:created)
      |> render("drive_file.json", file: file)
    end
  end

  @doc """
  API Spec for :load folders action
  """
  def download_file_operation() do
    %Operation{
      tags: ["users", "files", "downloads"],
      summary: "Download file",
      description: "Get a file by name",
      operationId: "UserController.download_file",
      parameters: [
        Operation.parameter(:file_name, :path, %Schema{type: :string}, "file name",
          example: "some-drive-file",
          required: true
        )
      ],
      responses: %{
        200 => Operation.response("DownloadFile", "application/json", Schemas.DriveFileResponse)
      }
    }
  end

  def download_file(conn, %{file_name: file_name}) do
    params = [
      includeItemsFromAllDrives: true,
      supportsAllDrives: true,
      # corpora: "allDrives",
      spaces: "appDataFolder"
    ]

    with {:ok, %Goth.Token{token: token}} <- Goth.fetch(ExPoints.Goth),
         drive_conn = GoogleApi.Drive.V3.Connection.new(token),
         {:ok, file_object} <- get_object(drive_conn, file_name, params),
         {:ok, %{body: body}} <- download_file(drive_conn, file_object.id, params) do

      content = CSV.decode([body], headers: true) |> Enum.map(fn {_, val} -> val end)

      render(conn, "folder.json", folder: file_object, sub_folders: content)
    end
  end

  defp upload_to_google_drive(%{file: %Plug.Upload{path: path} = upload} = params, opts \\ []) do
    with {:ok, %Goth.Token{token: token}} <- Goth.fetch(ExPoints.Goth),
         conn = GoogleApi.Drive.V3.Connection.new(token),
         {:ok, destination_folder_id} <- get_upload_folder(conn, params) do
      file_meta = build_file_meta(upload, destination_folder_id)

      case params do
        %{request_type: "update"} ->
          app_conf_params = Keyword.merge([spaces: "appDataFolder"], opts) |> Keyword.delete(:corpora)
          with {:ok, %{id: file_id}} <- get_object(conn, upload.filename, app_conf_params) do
            GoogleApi.Drive.V3.Api.Files.drive_files_update_simple(conn, file_id, "multipart", file_meta, path, opts)
          end
        _->
          GoogleApi.Drive.V3.Api.Files.drive_files_create_simple(conn, "multipart", file_meta, path, opts)
      end
    end
  end

  defp build_file_meta(%Plug.Upload{filename: name} = upload, folder_id) do
    parent_folder_ids = List.wrap(folder_id)
    uuid = Ecto.UUID.generate()
    filename = if folder_id == ["appDataFolder"], do: name, else: "#{uuid}-#{name}"

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

  defp get_upload_folder(_conn, %{upload_folder: "appDataFolder"}), do: {:ok, ["appDataFolder"]}
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

  defp download_file(conn, file_id, params) do
    params = Keyword.merge([alt: "media"], params)
    GoogleApi.Drive.V3.Api.Files.drive_files_get(conn, file_id, params)
  end

  defp list_files(conn, root_folder_id, opts) do
    query = "'#{root_folder_id}' in parents"
    opts = Keyword.merge([q: query], opts)

    case GoogleApi.Drive.V3.Api.Files.drive_files_list(conn, opts) do
      {:ok, %{files: files}} ->
        {:ok, files}

      {:error, reason} ->
        {:error, reason}

      _unhandled_result ->
        {:error, :invalid_result}
    end
  end

  defp get_object(conn, object_name, opts \\ []) do
    query = "name = '#{object_name}'"
    opts = Keyword.merge([q: query], opts)

    case GoogleApi.Drive.V3.Api.Files.drive_files_list(conn, opts) do
      {:ok, %{files: [file]}} ->
        {:ok, file}

      {:ok, %{files: [_ | _] = files}} ->
        IO.inspect(files, limit: :infinity)
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

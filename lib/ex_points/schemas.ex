defmodule ExPoints.Schemas do
  require OpenApiSpex
  alias OpenApiSpex.Schema
  # alias ExPoints.Accounts.User

  defmodule User do
    OpenApiSpex.schema(%{
      title: "User",
      description: "A user of the app",
      type: :object,
      properties: %{
        id: %Schema{type: :integer, description: "User ID"},
        points: %Schema{type: :integer, description: "User points"}
      },
      required: [:points],
      example: %{
        "id" => 123,
        "points" => 50
      },
      "x-struct": __MODULE__
    })
  end

  defmodule UserRequest do
    OpenApiSpex.schema(%{
      title: "UserRequest",
      description: "POST body for creating a user",
      type: :object,
      properties: %{
        user: %Schema{anyOf: [User]}
      },
      required: [:user],
      example: %{
        "user" => %{
          "points" => 60
        }
      }
    })
  end

  defmodule UserResponse do
    @behaviour OpenApiSpex.Schema

    @schema %Schema{
      title: "UserResponse",
      description: "Response schema for single user",
      type: :object,
      properties: %{
        data: User
      },
      example: %{
        "id" => 123,
        "points" => 55
      },
      "x-struct": __MODULE__
    }

    def schema, do: @schema
  end

  defmodule UserListResponse do
    @behaviour OpenApiSpex.Schema

    @schema %Schema{
      title: "UserListResponse",
      description: "Response schema for user list",
      type: :object,
      properties: %{
        data: %Schema{
          type: :object,
          description: "User listing",
          properties: %{
            users: %Schema{type: :array, items: User},
            timestamp: %Schema{type: :string, description: "Update timestamp", format: :datetime}
          }
        }
      },
      example: %{
        "timestamp" => "2023-07-12 12:27:40",
        "users" => [Schema.example(User.schema())]
      }
    }

    def schema, do: @schema
    defstruct Map.keys(@schema.properties)
  end

  defmodule Image do
    OpenApiSpex.schema(%{
      title: "Image",
      description: "An image upload",
      type: :object,
      properties: %{
        name: %Schema{type: :string, description: "Image name"},
        mime_type: %Schema{type: :string, description: "Image mimeType"},
        google_drive_id: %Schema{type: :string, description: "Image google drive id"}
      },
      required: [:name, :mime_type],
      example: %{
        "name" => "pic1",
        "mime_type" => "image/jpeg",
        "google_drive_id" => "12wG234"
      },
      "x-struct": __MODULE__
    })
  end

  defmodule ImageRequest do
    OpenApiSpex.schema(%{
      title: "ImageRequest",
      description: "POST body for uploading an image",
      type: :object,
      properties: %{
        file: %Schema{type: :object},
        upload_folder: %Schema{type: :string, default: nil, description: "Image upload folder"}
      },
      required: [:file],
      example: %{
        "file" => %{},
        "upload_folder" => "images/oct"
      }
    })
  end

  defmodule ImageResponse do
    @behaviour OpenApiSpex.Schema

    @schema %Schema{
      title: "ImageResponse",
      description: "Response schema for single image",
      type: :object,
      properties: %{
        name: %Schema{type: :string, description: "Image name"},
        mime_type: %Schema{type: :string, description: "Image mimeType"}
      },
      required: [:name, :mime_type],
      example: %{
        "name" => "pic1",
        "mime_type" => "image/jpeg"
      },
      "x-struct": __MODULE__
    }

    def schema, do: @schema
  end

  defmodule FolderResponse do
    @behaviour OpenApiSpex.Schema

    @schema %Schema{
      title: "FolderResponse",
      description: "Response schema for single folder",
      type: :object,
      properties: %{
        folder: %Schema{
          type: :object,
          description: "Folder",
          properties: %{
            id: %Schema{type: :string, description: "folder id"},
            name: %Schema{type: :string, description: "folder name"}
          }
        },
        sub_folders: %Schema{
          type: :array,
          items: %Schema{
            type: :object,
            properties: %{
              remote_entity_name: %Schema{type: :string, description: "entity name"},
              drive_folder: %Schema{type: :string, description: "folder name"},
            }
          }
        }
      },
      required: [:folder, :sub_folders],
      example: %{
        "folder" => %{"id" => "someid", "name" => "somefoldername"},
        "sub_folders" => [
          %{"remote_entity_name" => "test", "drive_folder" => "somefoldername"}
        ]
      },
      "x-struct": __MODULE__
    }

    def schema, do: @schema
  end

  defmodule AppConfigUploadRequest do
    OpenApiSpex.schema(%{
      title: "AppConfigUploadRequest",
      description: "POST body for uploading a config file",
      type: :object,
      properties: %{
        file: %Schema{type: :object},
        upload_folder: %Schema{type: :string, default: nil, description: "App config upload folder"},
        request_type: %Schema{type: :string, default: nil, description: "App config upload type"}
      },
      required: [:file],
      example: %{
        "file" => %{},
        "upload_folder" => "appDataFolder"
      }
    })
  end

  defmodule DriveFileResponse do
    @behaviour OpenApiSpex.Schema

    @schema %Schema{
      title: "DriveFileResponse",
      description: "Response schema for single drive file",
      type: :object,
      properties: %{
        name: %Schema{type: :string, description: "file name"},
        mime_type: %Schema{type: :string, description: "file mimeType"}
      },
      required: [:name, :mime_type],
      example: %{
        "name" => "test-file.csv",
        "mime_type" => "text/csv"
      },
      "x-struct": __MODULE__
    }

    def schema, do: @schema
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

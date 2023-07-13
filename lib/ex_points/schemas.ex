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
end

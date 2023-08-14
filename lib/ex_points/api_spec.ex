defmodule ExPoints.ApiSpec do
  alias OpenApiSpex.{OpenApi, Server, Info, Paths}
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [
        # Populate the Server info from a phoenix endpoint
        Server.from_endpoint(ExPointsWeb.Endpoint, otp_app: :my_app)
      ],
      info: %Info{
        title: "Ex Points",
        version: "1.0"
      },
      # populate the paths from a phoenix router
      paths: Paths.from_router(ExPointsWeb.Router)
    }
    # discover request/response schemas from path specs
    |> OpenApiSpex.resolve_schema_modules()
  end
end

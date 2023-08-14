defmodule ExPoints.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    credentials =
      "/Users/dannykalaluka/Documents/Applications/GDriveKeys/expoints-credentials.json"
      |> File.read!()
      |> Jason.decode!()

    source = {:service_account, credentials, scopes: ["https://www.googleapis.com/auth/drive"]}

    children = [
      # Start the Ecto repository
      ExPoints.Repo,
      # Start the Telemetry supervisor
      ExPointsWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ExPoints.PubSub},
      # Start the Endpoint (http/https)
      ExPointsWeb.Endpoint,
      # Start a worker by calling: ExPoints.Worker.start_link(arg)
      # {ExPoints.Worker, arg}
      {Task.Supervisor, name: ExPoints.TaskSupervisor},
      {ExPoints.Workers.UserPoints, [[]]},
      {Goth, name: ExPoints.Goth, source: source}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, max_restarts: 1_000, name: ExPoints.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExPointsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

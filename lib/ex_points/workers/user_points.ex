defmodule ExPoints.Workers.UserPoints do
  @moduledoc """
  The user points server for managing actions such as
  1. Updating points using a random number generator
  2. Querying the database for all users with more points than the `min_number`
    but only retrieve at most 2 users.
  """

  use GenServer, restart: :permanent, shutdown: 10_000
  require Logger
  alias ExPoints.Accounts

  @max_users 2
  @min_points 0
  @max_points 100
  @update_after :timer.seconds(60)

  ## Client API

  @doc """
  Starts the user points server with the given options.
  """
  def start_link(arg, opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, arg, name: name)
  end

  @doc """
  Looks up for at most two users with points greater than `min_number` in `server`.

  Updates `server timestamp` to current timestamp as last query timestamp

  Returns `{:ok, users, prev_timestamp}`
  """
  def get_users(server \\ __MODULE__) do
    GenServer.call(server, :get_users, 30_000)
  end

  ## Server callbacks

  @impl true
  def init(_opts) do
    min_number = Enum.random(@min_points..@max_points)
    state = %{min_number: min_number, timestamp: nil}
    schedule_update()
    {:ok, state}
  end

  @impl true
  def handle_call(:get_users, _from, state) do
    users = Accounts.list_users(state.min_number, @max_users)
    prev_timestamp = state.timestamp
    state = %{state | timestamp: Accounts.timestamp()}
    {:reply, {:ok, users, prev_timestamp}, state}
  end

  @impl true
  def handle_info({:update_points, task_supervisor}, state) do
    Task.Supervisor.async_nolink(task_supervisor, fn ->
      Accounts.update_points(@min_points, @max_points)
    end)

    schedule_update()
    {:noreply, state}
  end

  @impl true
  def handle_info({task_ref, _result}, state) do
    Process.demonitor(task_ref, [:flush])
    min_number = Enum.random(@min_points..@max_points)
    {:noreply, %{state | min_number: min_number}}
  end

  @impl true
  def handle_info({:DOWN, _task_ref, _, _, reason}, state) do
    Logger.error("User points update failed with reason: #{inspect(reason)}")
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  defp schedule_update do
    Process.send_after(self(), {:update_points, ExPoints.TaskSupervisor}, @update_after)
  end
end

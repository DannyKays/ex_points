defmodule ExPoints.Workers.UserPointsTest do
  use ExPoints.DataCase
  alias ExPoints.AccountsFixtures
  alias ExPoints.Workers.UserPoints

  describe "ExPoints.Workers.UserPoints" do
    setup do
      child_spec = %{
        id: ExPoints.TaskSupervisorTest,
        start: {Task.Supervisor, :start_link, [[name: ExPoints.TaskSupervisorTest]]}
      }

      pid = start_supervised!(child_spec)
      min_number = Enum.random(0..100)
      state = %{min_number: min_number, timestamp: nil}
      [task_id: pid, state: state]
    end

    test "UserPoints.init/1 assigns a random min_number when initializing" do
      {:ok, state} = UserPoints.init([])
      assert state.min_number in 0..100
    end

    test "UserPoints.get_users/1 gets users with points more than min_number" do
      child_spec = %{
        id: UserPointsTest,
        start: {UserPoints, :start_link, [[], [name: UserPointsTest]]}
      }

      pid = start_supervised!(child_spec)

      result = UserPoints.get_users(pid)
      assert result == {:ok, [], nil}

      {:ok, _users, timestamp} = UserPoints.get_users(pid)
      assert not is_nil(timestamp)
    end

    test "UserPoints.handle_info/2 :: :update_points creates a task using async_nolink", %{
      state: state
    } do
      assert {:noreply, ^state} = UserPoints.handle_info(:update_points, state)
    end

    test "async_nolink/3 replies with {ref, result} as message on success", %{state: state} do
      _user = AccountsFixtures.user_fixture()
      UserPoints.handle_info({:update_points, ExPoints.TaskSupervisorTest}, state)
      assert_receive {_task_ref, {1 = _row_count, nil = _return}}, 5_000
    end

    test "async_nolink/3 sends a :DOWN message on terminate", %{state: state, task_id: pid} do
      UserPoints.handle_info({:update_points, ExPoints.TaskSupervisorTest}, state)

      Process.exit(pid, :normal)

      assert_receive {:DOWN, _task_ref, :process, _pid, _reason}, 5_000
    end
  end
end

defmodule Otp.S.A do
  use Application

  def start(_t, _a) do
    Otp.S.Top.start_link
  end
end

defmodule Otp.S.Top do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_child do
    Supervisor.start_child(__MODULE__, Otp.S.Child)
  end

  def init(:ok) do
    Supervisor.init([], strategy: :one_for_all)
  end
end

defmodule Otp.S.Child do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [Otp.Worker]
    Supervisor.init(children, strategy: :one_for_all)
  end
end

##

defmodule Otp.S.Client do
  def start_link(child_spec_list) when is_list(child_spec_list) do
    GenServer.start_link(Otp.S.Server, child_spec_list)
  end

  def start_child(supervisor, child_spec) do
    GenServer.call(supervisor, {:start_child, child_spec})
  end

  def terminate_child(supervisor, child) do
    GenServer.call(supervisor, {:terminate_child, child})
  end

  def restart_child(supervisor, child) when is_pid(child) do
    GenServer.call(supervisor, {:restart_child, child})
  end

  def count_children(supervisor) do
    GenServer.call(supervisor, :count_children)
  end

  def which_children(supervisor) do
    GenServer.call(supervisor, :which_children)
  end
end

defmodule Otp.S.Server do
  use GenServer

  def init(child_spec_list) do
    Process.flag(:trap_exit, true)

    pid_spec_mapping =
      child_spec_list
      |> start_children
      |> Enum.into(%{})

    {:ok, pid_spec_mapping}
  end

  def handle_call({:start_child, child_spec}, _from, state) do
    case start_child(child_spec) do
      {:ok, child} ->
        new_state = Map.put(state, child, child_spec)
        {:reply, {:ok, child}, new_state}

      :error ->
        {:reply, {:error, "error starting child"}, state}
    end
  end

  def handle_call({:terminate_child, child}, _from, state) do
    case terminate_child(child) do
      :ok ->
        new_state = Map.delete(state, child)
        {:reply, :ok, new_state}

      :error ->
        {:reply, {:error, "error terminating child"}, state}
    end
  end

  def handle_call({:restart_child, child}, _from, state) do
    case Map.fetch(state, child) do
      {:ok, child_spec} ->
        case restart_child(child, child_spec) do
          {:ok, new_child, child_spec} ->
            new_state =
              state
              |> Map.delete(child)
              |> Map.put(new_child, child_spec)

            {:reply, {:ok, new_child}, new_state}

          :error ->
            {:reply, {:error, "error restarting child"}, state}
        end

      :error ->
        {:reply, :ok, state}
    end
  end

  def handle_call(:count_children, _from, state) do
    {:reply, Enum.count(state), state}
  end

  def handle_call(:which_children, _from, state) do
    {:reply, state, state}
  end

  def handle_info({:EXIT, child, :normal}, state) do
    new_state = state |> Map.delete(child)
    {:noreply, new_state}
  end

  def handle_info({:EXIT, child, :killed}, state) do
    new_state = state |> Map.delete(child)
    {:noreply, new_state}
  end

  def handle_info({:EXIT, child, _reason}, state) do
    case Map.fetch(state, child) do
      {:ok, child_spec} ->
        case restart_child(child, child_spec) do
          {:ok, new_child, child_spec} ->
            new_state =
              state
              |> Map.delete(child)
              |> Map.put(new_child, child_spec)

            {:noreply, new_state}

          :error ->
            {:noreply, state}
        end

      _ ->
        {:noreply, state}
    end
  end

  def terminate(_reason, state) do
    terminate_children(state)
    :ok
  end

  defp start_children([]), do: []

  defp start_children([child_spec | tail]) do
    case start_child(child_spec) do
      {:ok, child} ->
        [{child, child_spec} | start_children(tail)]

      :error ->
        :error
    end
  end

  defp start_child({m, f, a}) do
    case apply(m, f, a) do
      {:ok, child} when is_pid(child) ->
        Process.link(child)
        {:ok, child}

      _ ->
        :error
    end
  end

  defp terminate_children(%{}), do: :ok

  defp terminate_children(state) do
    Enum.each(state, fn {child, _} -> terminate_child(child) end)
  end

  defp terminate_child(child) do
    Process.exit(child, :kill)
    :ok
  end

  defp restart_child(child, child_spec) when is_pid(child) do
    case terminate_child(child) do
      :ok ->
        case start_child(child_spec) do
          {:ok, new_child} ->
            {:ok, new_child, child_spec}

          :error ->
            :error
        end

      :error ->
        :error
    end
  end
end

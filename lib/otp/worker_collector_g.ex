defmodule WorkerCollectorG do
  def call([], _f), do: []

  def call(list, f) do
    {:ok, collector} = WorkerCollectorG.Collector.start_link(self(), Enum.count(list))
    map(list, f, collector)
    receive_r()
  end

  defp map([], _f, _collector), do: []

  defp map([head | tail], f, collector) do
    {:ok, worker} = WorkerCollectorG.Worker.start_link(collector)
    WorkerCollectorG.Worker.do_it(worker, head, f)
    map(tail, f, collector)
  end

  defp receive_r do
    IO.puts("receiving result...")

    receive do
      {:ok, r} -> r
      :error -> :error
    end
    |> inspect
    |> IO.puts()
  end
end

defmodule WorkerCollectorG.Worker do
  use GenServer

  def start_link(collector) do
    GenServer.start_link(__MODULE__, collector, [])
  end

  def do_it(worker, e, f) do
    GenServer.cast(worker, {:do_it, e, f})
  end

  def init(collector) do
    {:ok, collector}
  end

  def handle_cast({:do_it, e, f}, collector) do
    WorkerCollectorG.Collector.collect(collector, {:ok, f.(e)})
    {:stop, :normal, collector}
  end

  def terminate(reason, _collector) do
    IO.puts("terminate worker with reason(#{reason})")
    :ok
  end
end

defmodule WorkerCollectorG.Collector do
  use GenServer

  def start_link(pid, count, r \\ []) do
    GenServer.start_link(__MODULE__, %{pid: pid, count: count, r: r}, [])
  end

  def collect(collector, {:ok, v}) do
    GenServer.cast(collector, {:collect, v})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:collect, v}, state) do
    %{pid: pid, count: count, r: r} = state

    new_r = [v | r]
    new_count = count - 1
    new_state = %{pid: pid, count: new_count, r: new_r}

    if new_count == 0 do
      {:stop, :normal, new_state}
    else
      {:noreply, new_state}
    end
  end

  def terminate(reason, %{pid: pid, r: r}) do
    IO.puts("collector terminate (#{reason})")
    sorted_r = r |> Enum.sort()
    send(pid, {:ok, sorted_r})
    :ok
  end
end

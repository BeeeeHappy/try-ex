defmodule WorkerCollectorG do
  def call([], _f), do: []

  def call(list, f) do
    collector = WorkerCollector.Collector.start(self(), Enun.count(list))
    map(list, f, collector)
    receive_r()
  end

  defp map([], _f, _collector), do: []

  defp map([head | tail], f, collector) do
    worker =
      spawn(
        WorkerCollector.Worker,
        :start,
        [collector, head, f]
      )

    send(worker, {head, f})
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

defmodule WorkerCollector.Worker do
  def start(collector, e, f) do
    v = f.(e)
    send(collector, {:ok, v})
  end
end

defmodule WorkerCollector.Collector do
  use GenServer

  def start(pid, count, r \\ []) do
    GenServer.start(%{pid: pid, count: count, r: r})
  end

  def collect(collector, {:ok, v}) do
    GenServer.cast(collector, {:collect, v})
  end

  def collect(collector, :error) do
    :invalid_value
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
    sorted_r = r |> Enum.sort()
    send(pid, {:ok, sorted_r})
    :ok
  end
end


defmodule WorkerCollector do
  def call([], _f), do: []

  def call(list, f) do
    collector = spawn()
    map(list, f, collector)
    receive_r
  end

  defp map([], _f, _collector), do: []

  defp map([head | tail], f, collector) do
    worker = spawn
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
  def loop(pid, count, r \\ []) do
    new_r =
      receive do
        {:ok, v} -> [v | r]
        :error -> r
      end

    new_count = count - 1

    if new_count == 0 do
      sorted_r = new_r |> Enum.sort()
      send(pid, {:ok, sorted_r})
    else
      loop(pid, new_count, new_r)
    end
  end
end

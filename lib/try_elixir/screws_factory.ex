defmodule ScrewsFactory do
  def run(pieces) do
    pieces
    |> Stream.chunk_every(50)
    |> Stream.flat_map(&add_thread/1)
    |> Stream.chunk_every(100)
    |> Stream.flat_map(&add_head/1)
    |> Enum.each(&output/1)
  end

  defp add_thread(pieces) do
    Process.sleep(50)
    pieces |> Enum.map(fn e -> e <> "--" end)
  end

  defp add_head(pieces) do
    Process.sleep(100)
    pieces |> Enum.map(fn e -> "o" <> e end)
  end

  defp output(screw) do
    IO.inspect(screw)
  end
end

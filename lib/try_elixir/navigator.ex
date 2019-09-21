defmodule Navigator do
  def navigate(path) do
    IO.puts("Start navigate: #{path}")
    navigate(path, 0)
  end

  def navigate(path, level) do
    targets = File.ls!(path)
    go_through(targets, path, level)
  end

  def go_through([], _pre_path, _level), do: nil

  def go_through([head | tail], pre_path, level) do
    print(head, level)

    combined_relative_path = "#{pre_path}/#{head}"
    expanded_path = Path.expand(combined_relative_path)

    if File.dir?(expanded_path) do
      navigate(combined_relative_path, level + 1)
    end

    go_through(tail, pre_path, level)
  end

  def print(target, level) do
    target_space = List.duplicate(" ", level) |> Enum.join()
    target_type = if(File.dir?(target), do: "+", else: "-")
    IO.puts("#{target_space}#{target_type} #{target}")
  end
end

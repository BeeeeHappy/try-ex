defmodule TryElixir.Recursion do
  def map([], _f), do: []
  def map([head | tail], f), do: [f.(head) | map(tail, f)]

  def reduce([], _f), do: nil
  def reduce([head | tail], f), do: reduce(tail, f, head)
  def reduce([], _f, acc), do: acc
  def reduce([head | tail], f, acc), do: reduce(tail, f, f.(head, acc))

  def filter([], _f), do: []

  def filter([head | tail], f) do
    if f.(head) do
      [head | filter(tail, f)]
    else
      filter(tail, f)
    end
  end

  def sum([]), do: 0
  def sum([head | tail]), do: sum(tail, head)
  def sum([], acc), do: acc
  def sum([head | tail], acc), do: sum(tail, head + acc)

  def find_max([]), do: nil
  def find_max([head | tail]), do: find_max(tail, head)
  def find_max([], max), do: max

  def find_max([head | tail], max) do
    if head > max do
      find_max(tail, head)
    else
      find_max(tail, max)
    end
  end

  def find_min([]), do: nil
  def find_min([head | tail]), do: find_min(tail, head)
  def find_min([], min), do: min

  def find_min([head | tail], min) do
    if head < min do
      find_min(tail, head)
    else
      find_min(tail, min)
    end
  end

  def sort
end

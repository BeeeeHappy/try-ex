defmodule TryElixir.Recursion do
  # tail recursion
  def factorial(n), do: factorial(n, 1)
  def factorial(0, acc), do: acc
  def factorial(n, acc), do: factorial(n - 1, acc * n)

  # factorial with limit lazy data structure
  def factorial_lazy_1(0), do: 1

  def factorial_lazy_1(n) do
    1..10000
    |> Enum.take(n)
    |> Enum.reduce(1, &(&1 * &2))
  end

  # factorial with unlimit lazy way
  def factorial_lazy_2(0), do: 1

  def factorial_lazy_2(n) do
    Stream.iterate(1, &(&1 + 1))
    |> Enum.take(n)
    |> Enum.reduce(1, &(&1 * &2))
  end

  # capture named function
  def anonymous_factorial_1(n), do: (&factorial/1).(n)

  # body recursion
  def anonymous_factorial_2(n) do
    f = fn
      0, _f -> 1
      x, f -> x * f.(x - 1, f)
    end

    f.(n, f)
  end

  # tail recursion
  def anonymous_factorial_3(n) do
    f = fn
      {x, f} -> f.({x, 1, f})
      {0, acc, _f} -> acc
      {x, acc, f} -> f.({x - 1, acc * x, f})
    end

    f.({n, f})
  end

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

  def sort([]), do: []
  def sort([e]), do: [e]

  def sort(list) do
    split_number = Enum.count(list) |> div(2)
    {list_a, list_b} = Enum.split(list, split_number)
    sort_merge(sort(list_a), sort(list_b))
  end

  def sort_merge([], list), do: list
  def sort_merge(list, []), do: list

  def sort_merge([head_a | tail_a] = list_a, [head_b | tail_b] = list_b) do
    if head_a < head_b do
      [head_a | sort_merge(tail_a, list_b)]
    else
      [head_b | sort_merge(list_a, tail_b)]
    end
  end

  def flatten([]), do: []
  def flatten([head | tail]), do: flatten(tail, flatten(head))
  def flatten(element), do: [element]
  def flatten([], acc), do: acc
  def flatten([head | tail], acc) when is_list(head), do: flatten(tail, acc ++ flatten(head))
  def flatten([head | tail], acc), do: flatten(tail, acc ++ [head])
end

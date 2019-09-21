defmodule TryElixir.RecursionTest do
  use ExUnit.Case

  alias TryElixir.Recursion

  setup do
    %{
      ordered_list: [1, 2, 3, 4, 5],
      unordered_list: [1, 3, 5, 4, 2]
    }
  end

  test "factorial" do
    assert Recursion.factorial(5) == 120
  end

  test "factorial_lazy_1" do
    assert Recursion.factorial_lazy_1(5) == 120
  end

  test "factorial_lazy_2" do
    assert Recursion.factorial_lazy_2(5) == 120
  end

  test "anonymous_factorial_1" do
    assert Recursion.anonymous_factorial_1(5) == 120
  end

  test "anonymous_factorial_2" do
    assert Recursion.anonymous_factorial_2(5) == 120
  end

  test "anonymous_factorial_3" do
    assert Recursion.anonymous_factorial_3(5) == 120
  end

  test "map", %{ordered_list: ordered_list} do
    assert Recursion.map(ordered_list, fn e -> e * e end) == [1, 4, 9, 16, 25]
  end

  test "reduce", %{ordered_list: ordered_list} do
    assert Recursion.reduce(ordered_list, fn e, acc -> e + acc end) == 15
  end

  test "filter", %{ordered_list: ordered_list} do
    assert Recursion.filter(ordered_list, fn e -> rem(e, 2) == 0 end) == [2, 4]
  end

  test "sum", %{ordered_list: ordered_list} do
    assert Recursion.sum(ordered_list) == 15
  end

  test "find_max", %{unordered_list: unordered_list} do
    assert Recursion.find_max(unordered_list) == 5
  end

  test "find_min", %{unordered_list: unordered_list} do
    assert Recursion.find_min(unordered_list) == 1
  end

  test "sort", %{unordered_list: unordered_list, ordered_list: ordered_list} do
    assert Recursion.sort(unordered_list) == ordered_list
  end
end

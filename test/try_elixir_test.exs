defmodule TryElixirTest do
  use ExUnit.Case
  doctest TryElixir

  test "greets the world" do
    assert TryElixir.hello() == :world
  end
end

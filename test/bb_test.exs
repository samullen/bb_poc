defmodule BbTest do
  use ExUnit.Case
  doctest Bb

  test "greets the world" do
    assert Bb.hello() == :world
  end
end

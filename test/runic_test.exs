defmodule RunicTest do
  use ExUnit.Case
  doctest Runic

  test "greets the world" do
    assert Runic.hello() == :world
  end
end

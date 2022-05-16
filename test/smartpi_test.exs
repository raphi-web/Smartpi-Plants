defmodule SmartpiTest do
  use ExUnit.Case
  doctest Smartpi

  test "greets the world" do
    assert Smartpi.hello() == :world
  end
end

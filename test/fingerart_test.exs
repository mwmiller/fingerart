defmodule FingerartTest do
  use ExUnit.Case
  doctest Fingerart

  test "greets the world" do
    assert Fingerart.hello() == :world
  end
end

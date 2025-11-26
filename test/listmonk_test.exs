defmodule ListmonkTest do
  use ExUnit.Case
  doctest Listmonk

  test "greets the world" do
    assert Listmonk.hello() == :world
  end
end

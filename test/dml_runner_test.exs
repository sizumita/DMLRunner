defmodule DmlRunnerTest do
  use ExUnit.Case
  doctest DmlRunner

  test "greets the world" do
    assert DmlRunner.hello() == :world
  end
end

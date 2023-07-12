defmodule CliTest do
  use ExUnit.Case
  doctest Usweather

  import Usweather.CLI, only: [parse_args: 1]

  test "parse_args/1 returns :help if -h or --help is given" do
    assert parse_args(["-h", "anything"]) == :help
    assert parse_args(["--help", "anything"]) == :help
  end

  test "parse_args/1 returns the station_id if it is given" do
    assert parse_args(["KJFK"]) == "KJFK"
  end
end

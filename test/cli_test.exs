defmodule CliTest do
  use ExUnit.Case
  doctest Usweather

  import Usweather.CLI, only: [parse_args: 1]

  test "parse_args/1 returns {:help, state_code} if -h or --help followed by state_code is given" do
    assert parse_args(["-h", "AB"]) == {:help, "AB"}
    assert parse_args(["--help", "AB"]) == {:help, "AB"}
  end

  test "parse_args/1 returns the station_id if only an argument without options is given" do
    assert parse_args(["KJFK"]) == "KJFK"
    assert parse_args(["kdto"]) == "kdto"
  end

  test "parse_args/1 returns :badcmd if an invalid command is given" do
    assert parse_args(["-x"]) == :badcmd
    assert parse_args(["--anything"]) == :badcmd
    assert parse_args(["-h", "AB", "-x"]) == :badcmd
  end
end

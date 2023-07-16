defmodule Usweather.CLI do
  @moduledoc """
  Handles the command line parsing and the dispatch to the various functions that end up generating a table showing the latest weather information given by the US National Weather Service (https://www.weather.gov/documentation/services-web-api) for the station_id issued as the command argument (or a table showing the list of the available station_ids within the required state, if the command is issued with the -h or --help options followed by the state_code given as argument)
  """
  def main(argv) do
    argv
    |> parse_args()
    |> process()
  end

  @doc """
  `argv` can be -h or --help followed by a state_code.
  Otherwise it is a list of chars representing the station_id.
  Returns a station_id string, or a tuple `{:help, state_code}`
  if -h or --help followed by state_code was given.
  """
  def parse_args(argv) do
    OptionParser.parse(argv,
      strict: [help: :boolean],
      aliases: [h: :help]
    )
    # The OptionParser.parse() function returns a tuple of three elements:
    # . a keyword list of the options (switches and aliases), elem(0)
    # . a list of the remaining arguments, elem(1)
    # . a list of errors, elem(2)
    |> args_to_internal_representation()
  end

  @doc """
  Recieves a tuple of three elements:
  . a keyword list of the options (switches and aliases),
  . a list of the remaining arguments,
  . a list of errors.
  Returns:
  . a station_id string, or
  . a tuple `{:help, state_code}` if -h or --help followed by state_code was given, or
  . :badcmd if the command was not recognized.
  """
  def args_to_internal_representation({[help: true], state_code, []})
      when length(state_code) == 1 do
    {:help, state_code |> Enum.join() |> String.upcase()}
  end

  def args_to_internal_representation({[], station_id, []})
      when length(station_id) == 1 do
    # return station_id converted from a list of chars to a string
    station_id |> Enum.join() |> String.upcase()
  end

  def args_to_internal_representation(_), do: :badcmd

  @doc """
  If a tuple `{:help, state_code}` is given as input, it fetches the list of
  all the available station_ids in the given state_code and prints it in a table.
  If a station_id string is given as input, it fetches the latest weather
  information for the given station_id and prints it in a table.
  Bad commands are handled by displaying a usage message and halting the program.
  """
  def process(:badcmd) do
    IO.puts("\nusage: usweather <station_id> or usweather -h <state_code>\n")
    System.halt(0)
  end

  def process({:help, state_code}) do
    Usweather.NWS.fetch({:index, state_code})
    # if a successful response is given by the National Weather Service, the fetch
    # function parses it and returns a list of keyword lists, where each keyword list
    # has the keys :station_id, :state, :name and the values are the text of the tags.
    # The Formatter module prints the list of keyword lists in a table.
    |> Usweather.Formatter.print_table_for_columns(["station_id", "state", "name"])
  end

  def process(station_id) do
    Usweather.NWS.fetch(station_id)
    # if a successful response is given by the National Weather Service, the fetch
    # function parses it and returns a keyword list, where the keys are atoms
    # representing the names of the xml tags (i.e., :location, :station_id, :observation_time,
    # :weather, temperature_string, :relative_humidity, :wind_string, :pressure_string,
    # :dewpoint_string and :visibility_mi), and the values are the text of the tags.
    # The Formatter module prints the keyword list in a table.
    |> Usweather.Formatter.print_table_for_rows([
      "location",
      "station_id",
      "observation_time",
      "weather",
      "temperature_string",
      "relative_humidity",
      "wind_string",
      "pressure_string",
      "dewpoint_string",
      "visibility_mi"
    ])
  end
end

defmodule Usweather.CLI do
  @moduledoc """
  Handles the command line parsing and the dispatch to the various functions that end up generating a table showing the latest weather information given by the US National Weather Service (https://www.weather.gov/documentation/services-web-api) for the station_id issued as the command argument (or a table showing the list of the available station_ids in a required state if the command is issued with the -h or --help options followed by the state_code given as argument)
  """
  def run(argv) do
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

  def args_to_internal_representation({[help: true], state_code, []}) do
    {:help, Enum.join(state_code)}
  end

  def args_to_internal_representation({[], station_id, []}) do
    # return station_id converted from a list of chars to a string
    Enum.join(station_id)
  end

  def args_to_internal_representation(_), do: :badcmd

  def process(:badcmd) do
    IO.puts("\nusage: usweather <station_id> or usweather -h <state_code>\n")
    System.halt(0)
  end

  def process({:help, state_code}) do
    # fetch the list of all the available station_ids in the given state_code
    Usweather.NWS.fetch({:index, state_code})
    # deal with a possible error response from the fetch,
    # show the parsed information otherwise
    |> decode_response()
    |> Usweather.Formatter.print_table_for_columns(["station_id", "state", "name"])
  end

  def process(station_id) do
    # fetch the weather information for the given station_id
    Usweather.NWS.fetch(station_id)
    # deal with a possible error response from the fetch,
    # show the parsed information otherwise
    |> decode_response()
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

  def decode_response({:ok, body}) do
    body
  end

  def decode_response({:error, error_body}) do
    IO.puts("Error fetching from US National Weather Service: #{error_body}")
    System.halt(2)
  end
end

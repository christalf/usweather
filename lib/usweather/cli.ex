defmodule Usweather.CLI do
  @moduledoc """
  Handles the command line parsing and the dispatch to the various functions that end up generating a table showing the latest weather information given by the US National Weather Service (https://www.weather.gov/documentation/services-web-api) for the station_id issued as the command argument (or a table showing the list of the available station_ids if the command is issued with the -h or --help options)
  """
  def run(argv) do
    argv
    |> parse_args()
    |> process()
  end

  @doc """
  `argv` can be -h or --help.  Otherwise it is a weather station_id.
  Returns a station_id string,  or `:help` if -h or --help was given.
  """
  def parse_args(argv) do
    OptionParser.parse(argv,
      switches: [help: :boolean],
      aliases: [h: :help]
    )

    # The OptionParser.parse() function returns a tuple of three elements:
    # . a keyword list of the options (switches and aliases), elem(0)
    # . a list of the remaining arguments, elem(1)
    # . a list of errors, elem(2)
    |> args_to_internal_representation()
  end

  def args_to_internal_representation({[help: true], _, _}) do
    :help
  end

  def args_to_internal_representation({_, station_id, _}) do
    # return station_id converted from a list of chars to a string
    Enum.join(station_id)
  end

  # def args_to_internal_representation(_) do
  #   :help
  # end

  def process(:help) do
    IO.puts("usage: usweather <station_id>")

    # fetch the list of all the available station_ids
    Usweather.NWS.fetch(:index)
    # deal with a possible error response from the fetch
    # show the parsed information otherwise
    |> decode_response()
  end

  def process(station_id) do
    # fetch the weather information for the given station_id
    Usweather.NWS.fetch(station_id)
    # deal with a possible error response from the fetch,
    # show the parsed information otherwise
    |> decode_response()
  end

  def decode_response({:ok, body}), do: body

  def decode_response({:error, error_body}) do
    IO.puts("Error fetching from US National Weather Service: #{error_body}")
    System.halt(2)
  end
end

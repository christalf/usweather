defmodule Usweather.NWS do
  @moduledoc """
  Handles the fetching of the weather information from the US National Weather Service (https://www.weather.gov/documentation/services-web-api)
  """
  require Logger

  # use a module attribute to fetch the value at compile time
  @headers Application.compile_env(:usweather, :headers)
  @nws_stations_url Application.compile_env(:usweather, :nws_stations_url)
  @nws_api_url Application.compile_env(:usweather, :nws_api_url)

  @doc """
  `which_page` can be a tuple `{:index, state_code}` or a string representing a station_id.
  Fetches the page corresponding to `which_page` and, if the response is successful,
  parses the response body and returns:
  . a list of keyword lists, each keyword list having as keys atoms representing the tags
  `<station_id>`, `<state_code>` and `<station_name>` (i.e., :station_id, :state and :name),
  and the values are the text of corrisponding xml tags.
  . a keyword list, where the keys are atoms representing the names of the weather information
  tags we are interesed in (i.e., :location, :station_id, :observation_time, :weather, temperature_string, :relative_humidity, :wind_string, :pressure_string, :dewpoint_string
  and :visibility_mi), and the values are the text of the tags.
  """
  def fetch(which_page) do
    Logger.info("Fetching #{inspect(which_page)}")

    get_page_url(which_page)
    |> HTTPoison.get(@headers)
    |> handle_response(which_page)
  end

  @doc """
  Builds the URL for the page to fetch, that is, the URL for the Natinal Weather Service
  index page if `which_page` is `{:index, state_code}` that contains all the station_ids,
  or the URL for the page that contains the latest weather information for the given
  station_id if `which_page` is a string representing a station_id.
  """
  def get_page_url({:index, _state_code}),
    do: @nws_stations_url

  def get_page_url(station_id),
    do: "#{@nws_api_url}/stations/#{station_id}/observations/latest"

  @doc """
  Handles the response from the National Weather Service.
  If the response is successful, it parses the response body and returns:
  . a list of keyword lists, each keyword list having as keys atoms representing the tags
  `<station_id>`, `<state_code>` and `<station_name>` (i.e., :station_id, :state and :name),
  and the values are the text of corrisponding xml tags.
  . a keyword list, where the keys are atoms representing the names of the weather information
  tags we are interesed in (i.e., :location, :station_id, :observation_time, :weather, temperature_string, :relative_humidity, :wind_string, :pressure_string, :dewpoint_string
  and :visibility_mi), and the values are the text of the tags.
  If the response is not successful, it prints the error message and halts the program.
  """
  def handle_response({_, %{status_code: status_code, body: body}}, {:index, state_code}) do
    Logger.info("Got response: status_code=#{status_code}")
    Logger.debug(fn -> inspect(body) end)

    decode_response = status_code |> check_for_error()

    if decode_response == :ok do
      body |> Usweather.XmlParser.stations_index(state_code)
    else
      IO.puts("Error fetching from US National Weather Service: #{body}")
      System.halt(2)
    end
  end

  def handle_response({_, %{status_code: status_code, body: body}}, _station_id) do
    Logger.info("Got response: status_code=#{status_code}")
    Logger.debug(fn -> inspect(body) end)

    decode_response = status_code |> check_for_error()

    if decode_response == :ok do
      body |> Usweather.XmlParser.latest_weather_report()
    else
      IO.puts("Error fetching from US National Weather Service: #{body}")
      System.halt(2)
    end
  end

  @doc """
  Checks if the status code is 200 (OK) and returns :ok if it is, :error otherwise.
  """
  def check_for_error(200), do: :ok
  def check_for_error(_), do: :error
end

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
  Fetches the page corresponding to `which_page` and returns a tuple `{status_code, body}`.
  """
  def fetch(which_page) do
    Logger.info("Fetching #{inspect(which_page)}")

    get_page_url(which_page)
    |> HTTPoison.get(@headers)
    |> handle_response(which_page)
  end

  def get_page_url({:index, _state_code}),
    do: @nws_stations_url

  def get_page_url(station_id),
    do: "#{@nws_api_url}/stations/#{station_id}/observations/latest"

  def handle_response({_, %{status_code: status_code, body: body}}, {:index, state_code}) do
    Logger.info("Got response: status_code=#{status_code}")
    Logger.debug(fn -> inspect(body) end)

    {
      status_code |> check_for_error(),
      body |> Usweather.XmlParser.stations_index(state_code)
    }
  end

  def handle_response({_, %{status_code: status_code, body: body}}, _station_id) do
    Logger.info("Got response: status_code=#{status_code}")
    Logger.debug(fn -> inspect(body) end)

    {
      status_code |> check_for_error(),
      body |> Usweather.XmlParser.latest_weather_report()
    }
  end

  def check_for_error(200), do: :ok
  def check_for_error(_), do: :error
end

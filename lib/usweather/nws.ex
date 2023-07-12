defmodule Usweather.NWS do
  @headers [
    {"User-agent", "theweatherapp.com contact@theweatherapp.com"},
    {"Accept", "application/vnd.noaa.obs+xml"}
  ]
  @nws_index_url "https://w1.weather.gov/xml/current_obs/index.xml"

  def fetch(which_page) do
    get_page_url(which_page)
    |> HTTPoison.get(@headers)
    |> handle_response(which_page)
  end

  def get_page_url(:index),
    do: @nws_index_url

  def get_page_url(station_id),
    do: "https://api.weather.gov/stations/#{station_id}/observations/latest"

  def handle_response({_, %{status_code: status_code, body: body}}, :index) do
    {
      status_code |> check_for_error(),
      body |> Usweather.XmlParser.stations_index()
    }
  end

  def handle_response({_, %{status_code: status_code, body: body}}, _station_id) do
    {
      status_code |> check_for_error(),
      body |> Usweather.XmlParser.latest_weather_report()
    }
  end

  def check_for_error(200), do: :ok
  def check_for_error(_), do: :error
end

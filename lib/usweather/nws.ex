defmodule Usweather.NWS do
  # use a module attribute to fetch the value at compile time
  @headers Application.compile_env(:usweather, :headers)
  @nws_stations_url Application.compile_env(:usweather, :nws_stations_url)
  @nws_api_url Application.compile_env(:usweather, :nws_api_url)

  def fetch(which_page) do
    get_page_url(which_page)
    |> HTTPoison.get(@headers)
    |> handle_response(which_page)
  end

  def get_page_url({:index, _state_code}),
    do: @nws_stations_url

  def get_page_url(station_id),
    do: "#{@nws_api_url}/stations/#{station_id}/observations/latest"

  def handle_response({_, %{status_code: status_code, body: body}}, {:index, state_code}) do
    {
      status_code |> check_for_error(),
      body |> Usweather.XmlParser.stations_index(state_code)
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

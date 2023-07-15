defmodule Usweather.Formatter do
  @moduledoc """
  Handles the formatting of the weather information returned by the US National Weather Service (https://www.weather.gov/documentation/services-web-api)
  """
  @doc """
  Uses TableRex.quick_render!() to generate a table showing the weather information or
  the available weather stations for the given state.
  """
  def print_table_for_rows(nws_info, rows) when not is_list(hd(nws_info)) do
    # `nws_info` is not a list of keyword lists, means that it is a keyword list where
    # the keys are atoms representing the names of the tags (i.e., :location, :station_id,
    # :observation_time, :weather, temperature_string, :relative_humidity, :wind_string,
    # :pressure_string, :dewpoint_string and :visibility_mi ), and the values are the text
    # of the tags.
    # `rows` is a list of strings representing the names of the tags.
    table_title = "Weather information for station_id #{nws_info[:station_id]}"
    col_titles = ["Item", "Information"]

    # match rows in a row_titles variable
    row_titles = rows

    # convert rows to atoms, because access calls for keywords expect the key
    # to be an atom
    keys = Enum.map(rows, &String.to_atom/1)

    # build the complete_rows variable, which is a list of rows, where each row is a list
    # of two elements: a row_title string element and the corresponding tag's text contained
    # in the nws_info keyword list.
    complete_rows =
      Enum.map(Enum.zip([row_titles, keys]), fn {row_title, key} ->
        [row_title, nws_info[key]]
      end)

    # render the table
    TableRex.quick_render!(complete_rows, col_titles, table_title)
    |> IO.puts()
  end

  def print_table_for_columns(nws_info, columns) when is_list(hd(nws_info)) do
    # `nws_info` is a list of keyword lists, where each keyword list has the keys
    # :station_id, :state, :name.
    table_title = "Available weather stations for required state"

    # match columns in a col_titles variable
    col_titles = columns

    # convert columns to atoms, because access calls for keywords expect the key
    # to be an atom
    keys = Enum.map(columns, &String.to_atom/1)

    # build the rows variable, which is a list of lists of the tags' texts contained in the
    # nws_info list of keyword lists, in the same order as the columns list.
    rows =
      Enum.map(nws_info, fn nws_info_item ->
        Enum.map(keys, &nws_info_item[&1])
      end)

    # render the table
    TableRex.quick_render!(rows, col_titles, table_title)
    |> IO.puts()
  end
end

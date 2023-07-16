defmodule Usweather.XmlParser do
  @moduledoc """
  Handles the parsing of the XML documents returned by the US National Weather Service (https://www.weather.gov/documentation/services-web-api)
  """
  import Record, only: [defrecord: 2, extract: 2]
  # Remember adding :xmerl to the extra_applications list in mix.exs
  defrecord :eliXmlElement, extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  defrecord :eliXmlText, extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

  @doc """
  `xml` is a string representing an XML document, which must be the response body of
  a successful HTTP request to the National Weather Service requiring the index page
  where all the station_ids are listed.
  `state_code` is a string representing a state code.
  Parses the XML document and returns a list of keyword lists, each keyword list having the keys :station_id, :state and :name, and the values are the text of the corresponding xml tags.
  """
  def stations_index(xml, state_code) do
    xml
    |> parse_xml()
    |> extract_stations(state_code)
  end

  @doc """
  `xml` is a string representing an XML document, which must be the response body of
  a successful HTTP request to the National Weather Service requiring the latest weather
  information for a given station_id.
  Parses the XML document and returns a keyword list, where the keys are atoms representing the names of the weather information tags we are interesed in (i.e., :location, :station_id, :observation_time, :weather, temperature_string, :relative_humidity, :wind_string, :pressure_string, :dewpoint_string and :visibility_mi), and the values are the text of the tags.
  """
  def latest_weather_report(xml) do
    xml
    |> parse_xml()
    |> extract_weather_report()
  end

  @doc """
  Uses the :xmerl library to parse the XML document.
  Returns the XML document as a list of XML elements, i.e., in a format Xmerl
  can work with.
  """
  def parse_xml(xml) do
    {doc, _} = xml |> :binary.bin_to_list() |> :xmerl_scan.string()
    doc
  end

  @doc """
  `xml` is a list of XML elements, i.e., in a format Xmerl can work with.
  The structure of the XML document is as follows: under the root tag
  `<wx_station_index>`, there are a number of `<station>` tags.
  Each `<station>` tag of the XML document contains the following tags:
  `<station_id>`, `<state>`, `<station_name>`.
  This function extracts the content (i.e. text) of all `<station_id>` and
  `<station_name>` tags, but only if the `<state>` tag matches the given state_code,
  and returns them in a list of keyword lists, each keyword list having the keys
  :station_id, :state and :name, with their corrisponding text values.
  """
  def extract_stations(xml, state_code) do
    list_of_station_ids =
      :xmerl_xpath.string('/wx_station_index/station/station_id/text()', xml)
      |> Enum.map(fn text -> eliXmlText(text, :value) |> to_string() end)

    list_of_states =
      :xmerl_xpath.string('/wx_station_index/station/state/text()', xml)
      |> Enum.map(fn text -> eliXmlText(text, :value) |> to_string() end)

    list_of_station_names =
      :xmerl_xpath.string('/wx_station_index/station/station_name/text()', xml)
      |> Enum.map(fn text -> eliXmlText(text, :value) |> to_string() end)

    complete_list = Enum.zip([list_of_station_ids, list_of_states, list_of_station_names])

    # now we can filter by state_code
    filtered_list = Enum.filter(complete_list, fn {_, state, _} -> state == state_code end)

    # if an invalid state_code is given, the list will be empty, so we can check for
    # that and return an error message; otherwise, we get a list of 3-tuples, where
    # each 3-tuple is a station_id, a state and a name, and we'll convert each 3-tuple
    # to a keyword list, where the keys are :station_id, :state, :name
    if Enum.empty?(filtered_list) do
      IO.puts(
        "State code: #{state_code} doesn't matches any of the National Weather Service's states"
      )

      System.halt(3)
    else
      Enum.map(filtered_list, fn {station_id, state, name} ->
        [
          {String.to_atom("station_id"), station_id},
          {String.to_atom("state"), state},
          {String.to_atom("name"), name}
        ]
      end)
    end
  end

  @doc """
  `xml` is a list of XML elements, i.e., in a format Xmerl can work with.
  The structure of the XML document is as follows: under the root tag
  `<current_observation>` there are a number of tags, from which we are interested
  in the following: `<location>`, `<station_id>`, `<observation_time>`, `<weather>`,
  `<temperature_string>`, `<relative_humidity>`, `<wind_string>`, `<pressure_string>`,
  `<dewpoint_string>` and `<visibility_mi>`.
  This function extracts the text of all these tags, and returns them in a keyword list,
  where the keys are the names of the tags with their corrisponding text values.
  """
  def extract_weather_report(xml) do
    list_of_tags = [
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
    ]

    report =
      for tag <- list_of_tags do
        :xmerl_xpath.string('/current_observation/#{tag}/text()', xml)
        |> Enum.map(fn text -> eliXmlText(text, :value) |> to_string() end)
      end

    # now each element of the list is a list with one string element,
    # so we now build a list of strings by extracting the first element of each list,
    # and then we check if any of the strings is empty, and if so, replace it with "N/A"
    report =
      for elem <- report do
        elem |> List.first()
      end
      |> Enum.map(fn value -> if is_nil(value), do: "N/A", else: value end)

    # we can zip the two lists together to build the list of 2-tuples
    Enum.zip([list_of_tags, report])
    # and convert the list of 2-tuples to a list of keyword lists
    |> Enum.map(fn {tag, value} -> {String.to_atom(tag), value} end)
  end
end

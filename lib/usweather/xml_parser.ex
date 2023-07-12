defmodule Usweather.XmlParser do
  import Record, only: [defrecord: 2, extract: 2]
  # Remember adding :xmerl to the extra_applications list in mix.exs
  defrecord :eliXmlElement, extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  defrecord :eliXmlText, extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

  def stations_index(xml) do
    xml
    |> parse_xml()
    |> extract_stations_index()
  end

  def latest_weather_report(xml) do
    xml
    |> parse_xml()
    |> extract_weather_report()
  end

  def parse_xml(xml) do
    {doc, _} = xml |> :binary.bin_to_list() |> :xmerl_scan.string()
    doc
  end

  def extract_stations_index(xml) do
    # The structure of the XML document is as follows: under the root tag
    # <wx_station_index>, there are a number of <station> tags.
    # Each <station> tag of the XML document contains the following tags:
    # <station_id>, <state>, <station_name>
    # We want to extract the text of all these tags, and return a list of
    # tuples where each tuple contains the station_id, state and station_name text

    list_of_station_ids =
      :xmerl_xpath.string('/wx_station_index/station/station_id/text()', xml)
      |> Enum.map(fn text -> eliXmlText(text, :value) end)

    list_of_states =
      :xmerl_xpath.string('/wx_station_index/station/state/text()', xml)
      |> Enum.map(fn text -> eliXmlText(text, :value) end)

    list_of_station_names =
      :xmerl_xpath.string('/wx_station_index/station/station_name/text()', xml)
      |> Enum.map(fn text -> eliXmlText(text, :value) end)

    Enum.zip([list_of_station_ids, list_of_states, list_of_station_names])
  end

  def extract_weather_report(xml) do
    # The structure of the XML document is as follows: under the root tag
    # <current_observation>, there are a number of tags from which we are interested
    # in the following: <location>, <station_id>, <observation_time>, <weather>,
    # <temperature_string>, <relative_humidity>, <wind_string>, <pressure_string>,
    # <dewpoint_string>, <visibility_mi>
    # We want to extract the text of all these tags, and return them in a list of tuples.

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
        |> Enum.map(fn text -> eliXmlText(text, :value) end)
      end

    Enum.zip([list_of_tags, report])
  end
end

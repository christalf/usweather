import Config

config :usweather,
  headers: [
    {"User-agent", "theweatherapp.com contact@theweatherapp.com"},
    {"Accept", "application/vnd.noaa.obs+xml"}
  ]

config :usweather,
  nws_stations_url: "https://w1.weather.gov/xml/current_obs/index.xml"

config :usweather,
  nws_api_url: "https://api.weather.gov"

config :logger,
  # `compile_time_purge_level:` is already deprecated
  compile_time_purge_matching: [[level_lower_than: :info]]

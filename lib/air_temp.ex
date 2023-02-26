defmodule Smartpi.AirData do
  def send() do
    {status, sd} = DHT.read(4, :dht22)

    air_sensors =
      case status do
        :ok ->
          tags = %{"device" => "pizero", "kind" => "air"}
          fields = %{"temperature" => "#{sd.temperature}", "humidity" => "#{sd.humidity}"}
          Smartpi.WriteAPI.send(tags, fields)

        :error ->
          {:error, 404}
      end

    air_sensors
  end
end

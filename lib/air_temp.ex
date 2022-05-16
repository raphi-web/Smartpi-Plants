defmodule Smartpi.AirData do
  def get_temp(address) do
    {status, sd} = DHT.read(4, :dht22)

    air_sensors =
      case status do
        :ok ->

          {Smartpi.Sensor.new_sensor(sd.temperature,"float" ,"air", "temperature")
          |> Smartpi.Sensor.send_sensor(address),

          Smartpi.Sensor.new_sensor(sd.humidity, "float" ,"air", "humidity")
          |> Smartpi.Sensor.send_sensor(address)}

        :error ->
          {:error, 404}
      end

      air_sensors
  end
end

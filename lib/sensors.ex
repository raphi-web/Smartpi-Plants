defmodule Smartpi.Sensor do
  defstruct datatype: nil ,type: nil, unit: nil, value: nil, send_status: nil, status_code: nil

  def new_sensor() do
    %Smartpi.Sensor{}
  end

  def new_sensor(value, datatype,  type, unit) do
    %Smartpi.Sensor{datatype: datatype, type: type, unit: unit, value: value}
  end

  def sensor_to_json(%Smartpi.Sensor{} = sensor) do
    Poison.encode!(sensor)
  end

  def send_sensor(%Smartpi.Sensor{} = sensor, url) do
     %Smartpi.Sensor{sensor | send_status: 404, status_code:  404 }
  end
end

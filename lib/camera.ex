defmodule Smartpi.Camera do
  def take_send_image(address) do
    Picam.set_size(1280, 0)
    Picam.next_frame()
    |> Base.encode64()
    |> Smartpi.Sensor.new_sensor("string", "plants", "camera")
    |> Smartpi.Sensor.send_sensor(address)
  end
end

defmodule Smartpi.LightIntensity do
  alias Circuits.I2C
  use Bitwise

  @register %{
    als_conf: 0x00,
    als_wh: 0x01,
    als_wl: 0x02,
    psm: 0x03,
    als: 0x04,
    white: 0x05,
    als_int: 0x06
  }

  @power_modes %{
    one: 0b001,
    two: 0b011,
    three: 0b101,
    four: 0b111
  }


  defstruct adress: 0x10,
            integration_time: 25,
            gain: :one,
            raw_value: nil,
            raw_white_value: nil,
            lux_value: nil,
            psm: :one


  def new() do
    %Smartpi.LightIntensity{}
  end

  def read_register(%Smartpi.LightIntensity{} = light_sensor, register) do
    {:ok, ref} = I2C.open("i2c-1")

    {sucess?, <<value::unsigned-big-integer-size(16)>>} =
      I2C.write_read(ref, light_sensor.adress, <<register>>, 2)
    I2C.close(ref)
    {sucess?, value}
  end

  def write_register(%Smartpi.LightIntensity{} = light_sensor, register, message) do
    {:ok, ref} = I2C.open("i2c-1")
    sucess? = I2C.write(ref, light_sensor.adress, <<register, message>>)
    I2C.close(ref)
    sucess?
  end

  def read_raw(%Smartpi.LightIntensity{} = light_sensor) do
    {sucess?, value} = read_register(light_sensor, @register.als)

    case sucess? do
      :ok -> %Smartpi.LightIntensity{light_sensor | raw_value: value}
      :error -> light_sensor
    end
  end

  def read_white(%Smartpi.LightIntensity{} = light_sensor) do
    {sucess?, value} = read_register(light_sensor, @register.white)

    case sucess? do
      :ok -> %Smartpi.LightIntensity{light_sensor | raw_white_value: value}
      :error -> light_sensor
    end
  end

  def calc_lux(%Smartpi.LightIntensity{} = light_sensor) do
    factor = get_conversion_factor(light_sensor)
    lux = light_sensor.raw_value * factor

    corrected_lux =
      cond do
        light_sensor.gain == :one_quater and lux > 1000 -> correct_high_lux(lux)
        light_sensor.gain == :one_eight and lux > 1000 -> correct_high_lux(lux)
        true -> lux
      end

    %Smartpi.LightIntensity{light_sensor | lux_value: corrected_lux}
  end

  def correct_high_lux(lux) do
    lux ** 4 * 6.0135e-13 + lux ** 3 * -9.3924e-09 + lux ** 2 * 8.1488e-05 + lux * 1.0023
  end

  def get_conversion_factor(%Smartpi.LightIntensity{} = light_sensor) do
    integration_time = light_sensor.integration_time
    gain = light_sensor.gain

    gain_factor =
      case gain do

        :two -> 1
        :one -> 2
        :one_quater -> 8
        :one_eight -> 16

      end

    integration_time_factor =
      case integration_time do
        25 -> 0.1152
        50 -> 0.0576
        100 -> 0.0288
        200 -> 0.0144
        400 -> 0.0072
        800 -> 0.0036
      end

    gain_factor * integration_time_factor
  end

  def reset_setting(%Smartpi.LightIntensity{} = light_sensor) do
    write_register(light_sensor, @register.als_conf, 0)
  end

  def disable_power_saving_mode(%Smartpi.LightIntensity{} = light_sensor) do
    write_register(light_sensor, @register.psm, 0)
  end


  def set_power_mode(%Smartpi.LightIntensity{} = light_sensor, :one) do
    sucess? = write_register(light_sensor, @register.psm, @power_modes.one)

    case sucess? do
      :ok -> Map.put(light_sensor, :psm, :one)
      {:error, _} -> light_sensor
    end
  end

  def set_power_mode(%Smartpi.LightIntensity{} = light_sensor, :two) do
    sucess? = write_register(light_sensor, @register.psm,@power_modes.two)

    case sucess? do
      :ok -> Map.put(light_sensor, :psm, :one)
      {:error, _} -> light_sensor
    end
  end

  def set_power_mode(%Smartpi.LightIntensity{} = light_sensor, :three) do
    sucess? = write_register(light_sensor, @register.psm, @power_modes.three)

    case sucess? do
      :ok -> Map.put(light_sensor, :psm, :one)
      {:error, _} -> light_sensor
    end
  end

  def set_power_mode(%Smartpi.LightIntensity{} = light_sensor, :four) do
    sucess? = write_register(light_sensor, @register.psm, @power_modes.four)

    case sucess? do
      :ok -> Map.put(light_sensor, :psm, :one)
      {:error, _} -> light_sensor
    end
  end

  def send() do
    light_sensor = new()
    |> read_raw()
    |> calc_lux()

    tags = %{"device" => "pizero", "kind" => "light"}
    fields = %{"lux" => "#{light_sensor.lux_value}", "raw" => "#{light_sensor.raw_value}"}
    Smartpi.WriteAPI.send(tags, fields)
  end


end

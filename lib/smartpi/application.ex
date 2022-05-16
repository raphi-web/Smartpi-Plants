defmodule Smartpi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Smartpi.Supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: Smartpi.Worker.start_link(arg)
        # {Smartpi.Worker, arg},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: Smartpi.Worker.start_link(arg)
      # {Smartpi.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: Smartpi.Worker.start_link(arg)
      # {Smartpi.Worker, arg},
      # {Smartpi.IntervallExecutor, %{timer: 20, exec_func: fn -> Process.sleep(10000); Smartpi.AirData.get_temp("http://192.168.1.110:8080/sensor") end}},
      # {Smartpi.IntervallExecutor, %{timer: 20, exec_func: fn -> Smartpi.SoilMoisture.get_moisture("http://192.168.1.110:8080/sensor") end}},
      Supervisor.child_spec(
        {Smartpi.IntervallExecutor,
         %{
           timer: 10,
           exec_func: fn ->
             Process.sleep(10000)
             Smartpi.AirData.get_temp("http://192.168.1.110:8080/sensor")
           end
         }},
        id: Air,
        restart: :transient
      ),
      Supervisor.child_spec(
        {Smartpi.IntervallExecutor,
         %{
           timer: 10,
           exec_func: fn ->
            Smartpi.SoilMoisture.get_moisture(5000, "http://192.168.1.110:8080/sensor")
           end
         }},
        id: Soil,
        restart: :transient
      ),

      Supervisor.child_spec(
        {Smartpi.IntervallExecutor,
         %{
           timer: 10,
           exec_func: fn ->
            Smartpi.LightIntensity.get_light("http://192.168.1.110:8080/sensor")
           end
         }},
        id: Light,
        restart: :transient
      ),

      {Picam.Camera, []},
      {Plug.Cowboy, scheme: :http, plug: Smartpi.Router, options: [port: 80]}
    ]
  end

  def target() do
    Application.get_env(:smartpi, :target)
  end
end

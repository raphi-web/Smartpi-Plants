defmodule Smartpi.Application do
  use Application

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Smartpi.Supervisor]

    children = [] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    []
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: Smartpi.Worker.start_link(arg)
      {Smartpi.WriteAPI,
       {"SmartHome", "SmartHome",
        "GEGQziU-rfz7fjCWJMVgJ0xuxbbQadSrqex6Y_6odEmsuINsRQdG9c7RcwSZa9aUI-6AL0wTRtOC3hZ8hFwRIQ==",
        "http://192.168.1.110:8086"}},
      {Picam.Camera, []},
      Supervisor.child_spec(
        {Smartpi.IntervallExecutor,
         %{
           timer: 10,
           exec_func: fn ->
             Process.sleep(1000)
             Smartpi.SoilMoisture.send(5000)
           end,
           name: Soil
         }},
        id: Soil,
        restart: :transient
      ),
      Supervisor.child_spec(
        {Smartpi.IntervallExecutor,
         %{
           timer: 10,
           exec_func: fn ->
             Process.sleep(1000)
             Smartpi.LightIntensity.reset_setting(Smartpi.LightIntensity.new())
             Smartpi.LightIntensity.send()
           end,
           name: Light
         }},
        id: Light,
        restart: :transient
      ),
      Supervisor.child_spec(
        {Smartpi.IntervallExecutor,
         %{
           timer: 120,
           exec_func: fn ->
             Process.sleep(1000)
             img = Smartpi.Camera.take_image()
             response = Smartpi.Camera.send_image(img, "http://192.168.1.110:80/image")
             {response, img}
           end,
           name: Image
         }},
        id: Camera,
        restart: :transient
      ),
      Supervisor.child_spec(
        {Smartpi.IntervallExecutor,
         %{
           timer: 10,
           exec_func: fn ->
             Process.sleep(50000)
             Smartpi.AirData.send()
           end,
           name: Air
         }},
        id: Air,
        restart: :transient
      ),
      {Plug.Cowboy, scheme: :http, plug: Smartpi.Router, options: [port: 80]}
    ]
  end

  def target() do
    Application.get_env(:smartpi, :target)
  end
end

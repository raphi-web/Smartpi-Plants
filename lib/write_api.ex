defmodule Smartpi.WriteAPI do
  defstruct measurement: "stat",
            tags: %{},
            fields: %{},
            org: nil,
            bucket: nil,
            token: nil,
            address: nil

  use GenServer

  def start_link({org, bucket, token, address}) do
    GenServer.start_link(__MODULE__, {org, bucket, token, address})
  end

  @impl true
  def init({org, bucket, token, address}) do
    Process.register(self(), WriteAPI)
    api = Smartpi.WriteAPI.new(org, bucket, token, address)
    {:ok, api}
  end

  @impl true
  def handle_call({:write, tags, fields}, _from, state) do
    {_, code} = state |> Smartpi.WriteAPI.write(tags, fields)
    {:reply, code, state}
  end

  @impl true
  def handle_call({:state}, _from, state) do
    {:reply, state, state}
  end

  def new(org, bucket, token, address) do
    %Smartpi.WriteAPI{org: org, bucket: bucket, token: token, address: address}
  end

  def set_measurement(%Smartpi.WriteAPI{} = write_api, measurement) do
    %{write_api | measurement: measurement}
  end

  def add_tag(%Smartpi.WriteAPI{} = write_api, key, value) do
    %{write_api | tags: Map.put(write_api.tags, key, value)}
  end

  def add_tags(%Smartpi.WriteAPI{} = write_api, key_value_map) do
    %{write_api | tags: Map.merge(write_api.tags, key_value_map)}
  end

  def set_tags(%Smartpi.WriteAPI{} = write_api, key_value_map) do
    %{write_api | tags: key_value_map}
  end

  def add_field(%Smartpi.WriteAPI{} = write_api, fieldname, value) do
    %{write_api | fields: Map.put(write_api.fields, fieldname, value)}
  end

  def add_fields(%Smartpi.WriteAPI{} = write_api, key_value_map) do
    %{write_api | fields: Map.merge(write_api.fields, key_value_map)}
  end

  def set_fields(%Smartpi.WriteAPI{} = write_api, key_value_map) do
    %{write_api | fields: key_value_map}
  end

  def send(tags, fields) do
    GenServer.call(WriteAPI, {:write, tags, fields}, 1000)
  end

  def write(%Smartpi.WriteAPI{} = write_api, tags, fields) do
    HTTPoison.start()
    write_api_data = write_api |> set_tags(tags) |> set_fields(fields)

    response =
      HTTPoison.post!(
        # add address
        write_api_data.address <>
          "/api/v2/write?org=#{write_api_data.org}&bucket=#{write_api_data.bucket}",
        to_line_protocol(write_api_data),
        [
          {"Content-Type", "text/plain; charset=utf-8"},
          {"Accept", "application/json"},
          {"Authorization","Token " <> write_api_data.token}
        ]
      )

    {write_api, response}
  end

  defp to_line_protocol(%Smartpi.WriteAPI{} = write_api) do
    write_api.measurement <> "," <> to_str(write_api.tags) <> " " <> to_str(write_api.fields)
  end

  @spec to_str(map) :: binary
  def to_str(map) do
    cond do
      length(Map.keys(map)) == 1 ->
        [{k, v}] = Enum.to_list(map)
        k <> "=" <> v

      true ->
        String.slice(
          Enum.reduce(map, "", fn {k, v}, acc ->
            acc <> k <> "=" <> v <> ","
          end),
          0..-2
        )
    end
  end
end

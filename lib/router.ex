defmodule Smartpi.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  forward("/static", to: Webinterface.StaticRouter)

  get "/image" do
    image = Smartpi.IntervallExecutor.get_last_data(TransmitterImage)

    send_success =
      case image.send_status do
        :error -> false
        :ok -> true
      end

    conn
    |> put_resp_content_type("text/json")
    |> send_resp(200, '{"image":"#{image.value}", "send_success":"#{send_success}"}')
  end

  get "/camera_state" do
    status =
      case Smartpi.IntervallExecutor.is_running(TransmitterImage) do
        true -> "running"
        false -> "stopped"
      end

    conn
    |> put_resp_content_type("text/json")
    |> send_resp(200, '{"status":"#{status}"}')
  end

  get "/stop" do
    Smartpi.IntervallExecutor.stop(TransmitterImage)

    conn
    |> put_resp_content_type("text/json")
    |> send_resp(200, '{"status":"stopped"}')
  end

  get "/start" do
    [address, timer] =
      conn.query_string
      |> String.split("&")
      |> Stream.map(fn x -> String.split(x, "=") end)
      |> Enum.map(fn x -> URI.decode(Enum.at(x, 1)) end)

    Smartpi.IntervallExecutor.start_link(
      %{
        timer: String.to_integer(timer),
        exec_func: fn -> Smartpi.Camera.take_send_image(address) end
      },
      name: TransmitterImage
    )

    conn
    |> send_resp(200, address <> "" <> timer)
  end

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, "/resources/index.html")
  end

  match(_, do: send_resp(conn, 404, "Oooops!"))
end

defmodule Smartpi.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  forward("/static", to: Webinterface.StaticRouter)

  get "/image" do
    {response, img} = Smartpi.IntervallExecutor.get_last_data(Image)

    send_success =
      case response.status_code do
        200 -> true
        _ -> false
      end

    conn
    |> put_resp_content_type("text/json")
    |> send_resp(200, '{"image":"#{Base.encode64(img)}", "send_success":"#{send_success}"}')
  end

  get "/camera_state" do
    status =
      case Smartpi.IntervallExecutor.is_running(Image) do
        true -> "running"
        false -> "stopped"
      end

    conn
    |> put_resp_content_type("text/json")
    |> send_resp(200, '{"status":"#{status}"}')
  end

  get "/stop" do
    Smartpi.IntervallExecutor.stop(Image)

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
        exec_func: fn ->
          img = Smartpi.Camera.take_image()
          response = Smartpi.Camera.send_image(img, "http://192.168.1.110:80/image")
          {response, img}
        end
      },
      name: Image
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

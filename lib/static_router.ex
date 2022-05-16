defmodule Webinterface.StaticRouter do
  use Plug.Builder

  plug(Plug.Static, at: "/", from: "/resources/")
  plug(:not_found)

  def not_found(conn, _) do
    send_resp(conn, 404, "no static found")
  end
end

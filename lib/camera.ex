defmodule Smartpi.Camera do
  def take_image() do
    Picam.set_size(1280, 0)
    Picam.next_frame()
  end

  def send_image(img, address) do
    HTTPoison.post!(address, Base.encode64(img), [
      {"Content-Type", "text/plain; charset=utf-8"},
      {"Accept", "application/json; text/plain;"}
    ])
  end
end

defmodule Smartpi.IntervallExecutor do
  use GenServer

  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def init(state) do
    Process.register(self(), state.name)
    schedule_work(state.timer)
    {:ok, Map.put(state, :data, state.exec_func.())}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:work, state) do
    schedule_work(state.timer)
    {:noreply, Map.put(state, :data, state.exec_func.())}
  end

  defp schedule_work(timer) do
    Process.send_after(self(), :work, timer * 60 * 1000)
  end

  def stop(name) do
    pid = GenServer.whereis(name)

    if pid != nil do
      Process.exit(pid, :end)
    end
  end

  def get_by_name(name) do
    case GenServer.whereis(name) do
      nil -> nil
      pid -> get(pid)
    end
  end

  def is_running(name) do
    case GenServer.whereis(name) do
      nil -> false
      _ -> true
    end
  end

  def get_last_data(name) do
    pid = GenServer.whereis(name)

    case pid do
      nil ->
        {"", :error, ""}

      _ ->
        state = Smartpi.IntervallExecutor.get(pid)
        state.data
    end
  end
end

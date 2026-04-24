defmodule PowerMonitor.DataFetcher do
  @moduledoc "GenServer for fetching solar inverter data."
  use GenServer

  @reload_after 10
  @inverter_url "http://192.168.178.53/status/powerflow"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    debug = Keyword.get(opts, :debug, false)
    testing = Keyword.get(opts, :testing, false)
    ui_server = Keyword.fetch!(opts, :ui_server)
    url = Keyword.get(opts, :url, @inverter_url)

    :inets.start()

    state = %{
      ui_server: ui_server,
      url: url,
      testing: testing,
      debug: debug,
      test_step: -1
    }

    delay = if state.testing, do: 1_000, else: 0
    schedule_fetch(delay)

    {:ok, state}
  end

  @impl true
  def handle_info(:fetch_data, %{testing: true} = state) do
    {data, new_state} = test_data(state)
    PowerMonitor.UIDisplay.display_data(state.ui_server, data, state.debug)

    schedule_fetch(250)

    {:noreply, new_state}
  end

  def handle_info(:fetch_data, state) do
    {data, new_state} = {get_data(state), state}

    if data do
      PowerMonitor.UIDisplay.display_data(state.ui_server, data, state.debug)
    end

    schedule_fetch(@reload_after * 1_000)

    {:noreply, new_state}
  end

  defp schedule_fetch(delay) do
    Process.send_after(self(), :fetch_data, delay)
  end

  defp get_data(state) do
    url = String.to_charlist(state.url)

    case :httpc.request(:get, {url, []}, [], body_format: :binary) do
      {:ok, {{_, 200, _}, _, body}} ->
        Jason.decode!(body)

      other ->
        handle_network_error(state, format_error(other))
    end
  rescue
    e -> handle_network_error(state, Exception.message(e))
  end

  defp handle_network_error(state, reason) do
    PowerMonitor.UIDisplay.display_error(state.ui_server, reason)
    PowerMonitor.UIDisplay.show_countdown(state.ui_server, @reload_after)
    countdown(@reload_after)
  end

  defp countdown(seconds) do
    Enum.each(1..seconds, fn _ ->
      IO.write(".")
      Process.sleep(1_000)
    end)
  end

  defp format_error(error_message) do
    {:ok, {{_, 400, _}, _, body}} = error_message

    message =
      body
      |> Jason.decode!()
      |> Map.get("failure")

    inspect(message)
  end

  defp test_data(%{test_step: step} = state) do
    new_step = if step >= 10, do: 0, else: step + 1
    {make_data_set(new_step), %{state | test_step: new_step}}
  end

  defp make_data_set(value) do
    %{
      "site" => %{
        "rel_Autonomy" => value * 10,
        "P_PV" => value * 1000,
        "P_Grid" => value * 1000
      },
      "inverters" => [%{"SOC" => value * 10, "P" => value * 1000}]
    }
  end
end

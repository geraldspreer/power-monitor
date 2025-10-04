defmodule PowerMonitor do
  @moduledoc "Terminal power monitor for Fronius solar inverters."

  @reload_after 10
  @url          "http://192.168.178.53/status/powerflow"

  @block "█ "
  @red   "\e[38;5;166m"
  @reset "\e[0m"
  @empty "\e[38;5;238m█ \e[0m"

  @buying_colors      List.duplicate(1, 10)
  @benefit_colors     List.duplicate(2, 10)
  @consumption_colors List.duplicate(2, 8) ++ [3, 1]
  @performance_colors Enum.reverse(@consumption_colors)

  def main(args) do
    testing = "--test" in args
    debug   = "--debug" in args

    ui =
      MiniUI.new()
      |> MiniUI.clear()
      |> MiniUI.set_padding(2, 1)

    state = %{
      ui:        ui,
      url:       @url,
      testing:   testing,
      debug:     debug,
      test_step: -1
    }

    :inets.start()

    run(state)
  end

  defp run(state) do
    {data, state} =
      if state.testing do
        test_data(state)
      else
        {get_data(state), state}
      end

    display_values(state, data)
    Process.sleep(if state.testing, do: 1_000, else: @reload_after * 1_000)
    run(state)
  end

  defp get_data(state) do
    url = String.to_charlist(state.url)

    case :httpc.request(:get, {url, []}, [], body_format: :binary) do
      {:ok, {{_, 200, _}, _, body}} -> Jason.decode!(body)
      other                         -> handle_network_error(state, format_error(other))
    end
  rescue
    e -> handle_network_error(state, Exception.message(e))
  end

  defp handle_network_error(state, reason) do
    MiniUI.clear(state.ui)
    retry_loop(state, reason)
  end

  defp retry_loop(state, reason) do
    url = String.to_charlist(state.url)

    case :httpc.request(:get, {url, []}, [], body_format: :binary) do
      {:ok, {{_, 200, _}, _, body}} ->
        MiniUI.clear(state.ui)
        data = Jason.decode!(body)
        display_values(state, data)
        data

      other ->
        print_error(state, reason || format_error(other))
        countdown(@reload_after)
        retry_loop(state, format_error(other))
    end
  rescue
    e ->
      print_error(state, Exception.message(e))
      countdown(@reload_after)
      retry_loop(state, Exception.message(e))
  end

  defp print_error(state, reason) do
    MiniUI.home(state.ui)
    IO.write([@red, "Network Error:\n", reason, @reset, "\n"])
    MiniUI.label(state.ui, "Retry in #{@reload_after} seconds" <> String.duplicate(" ", 20), 0, 2)
    MiniUI.goto(state.ui, 20, 2)
  end

  defp countdown(seconds) do
    Enum.each(1..seconds, fn _ ->
      IO.write(".")
      Process.sleep(1_000)
    end)
  end

  defp format_error(term), do: inspect(term)

  defp show_level(state, value, x, y, divider, colors, label) do
    MiniUI.label(state.ui, label, 0, y)
    MiniUI.goto(state.ui, x, y)

    Enum.each(0..9, fn p ->
      if p < value / divider do
        IO.write(["\e[38;5;#{Enum.at(colors, p)}m", @block, @reset])
      else
        IO.write(@empty)
      end
    end)

    if state.debug, do: IO.write(" #{value}    ")
    MiniUI.goto(state.ui, state.ui.cols, state.ui.rows)
  end

  defp display_values(state, data) when is_map(data) do
    show_level(state, to_int(data["site"]["rel_Autonomy"]),
      16, 0, 10, @performance_colors, "Autonomy")

    show_level(state, to_int(hd(data["inverters"])["SOC"]),
      16, 3, 10, @performance_colors, "Battery")

    show_level(state, to_int(hd(data["inverters"])["P"]),
      16, 5, 1000, @consumption_colors, "Consumption")

    show_level(state, to_int(data["site"]["P_PV"]),
      16, 7, 1000, @benefit_colors, "Solar")

    grid_value = to_int(data["site"]["P_Grid"])
    colors     = if grid_value < 0, do: @benefit_colors, else: @buying_colors
    label      = if grid_value < 0, do: "Export", else: "Import"
    grid       = if abs(grid_value) < 100, do: 0, else: abs(grid_value)

    show_level(state, grid, 16, 9, 1000, colors, label)
  end

  defp display_values(_state, _data), do: :ok

  defp test_data(%{test_step: step} = state) do
    new_step = if step >= 9, do: 0, else: step + 1
    {make_data_set(new_step), %{state | test_step: new_step}}
  end

  defp make_data_set(value) do
    %{
      "site" => %{
        "rel_Autonomy" => value * 10,
        "P_PV"         => value * 1000,
        "P_Grid"       => value * 1000
      },
      "inverters" => [%{"SOC" => value * 10, "P" => value * 1000}]
    }
  end

  defp to_int(v) when is_float(v),   do: trunc(v)
  defp to_int(v) when is_integer(v), do: v
  defp to_int(v),                    do: trunc(v / 1)
end


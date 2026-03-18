defmodule PowerMonitor.UIDisplay do
  @moduledoc "GenServer for terminal UI display."
  use GenServer

  @red "\e[38;5;166m"
  @reset "\e[0m"
  @empty "\e[38;5;238m█ \e[0m"
  @block "█ "

  # 10 blocks of red
  @buying_colors List.duplicate(1, 10)

  # 10 blocks of green
  @benefit_colors List.duplicate(2, 10)

  # 8 blocks of green, 1 yellow, 1 red
  @consumption_colors List.duplicate(2, 8) ++ [3, 1]
  @performance_colors Enum.reverse(@consumption_colors)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    # Clear the terminal on start
    MiniUI.clear()

    state = %{
      ui: MiniUI.new(),
      debug: false
    }

    {:ok, state}
  end

  def display_data(server, data, debug \\ false) do
    if data do
      GenServer.call(server, {:display_data, data, debug})
    end
  end

  def display_error(server, reason) do
    GenServer.cast(server, {:display_error, reason})
  end

  def show_countdown(server, seconds) do
    GenServer.cast(server, {:show_countdown, seconds})
  end

  @impl true
  def handle_call({:display_data, data, debug}, _, state) do
    state = %{state | debug: debug}
    render_values(state, data)
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:display_error, reason}, state) do
    MiniUI.clear()
    MiniUI.home()

    IO.write([@red, "Network Error:\n", reason, @reset, "\n"])
    {:noreply, state}
  end

  @impl true
  def handle_cast({:show_countdown, seconds}, state) do
    MiniUI.label("Retrying in #{seconds} seconds" <> String.duplicate(" ", 20), 0, 2)
    MiniUI.goto(20, 2)
    {:noreply, state}
  end

  defp render_values(state, data) when is_map(data) do
    show_level(
      state,
      to_int(data["site"]["rel_Autonomy"]),
      16,
      0,
      10,
      @performance_colors,
      "Autonomy"
    )

    show_level(
      state,
      to_int(hd(data["inverters"])["SOC"]),
      16,
      3,
      10,
      @performance_colors,
      "Battery"
    )

    show_level(
      state,
      to_int(hd(data["inverters"])["P"]),
      16,
      5,
      1000,
      @consumption_colors,
      "Consumption"
    )

    show_level(state, to_int(data["site"]["P_PV"]), 16, 7, 1000, @benefit_colors, "Solar")

    grid_value = to_int(data["site"]["P_Grid"])
    colors = if grid_value < 0, do: @benefit_colors, else: @buying_colors
    label = if grid_value < 0, do: "Export", else: "Import"
    grid = if abs(grid_value) < 100, do: 0, else: abs(grid_value)

    show_level(state, grid, 16, 9, 1000, colors, label)
  end

  defp render_values(_state, _data), do: :ok

  defp show_level(state, value, x, y, divider, colors, label) do
    MiniUI.label(label, 0, y)
    MiniUI.goto(x, y)

    Enum.each(0..9, fn p ->
      if p < value / divider do
        IO.write(["\e[38;5;#{Enum.at(colors, p)}m", @block, @reset])
      else
        IO.write(@empty)
      end
    end)

    if state.debug, do: IO.write(" #{value}    ")
    MiniUI.goto(state.ui.cols, state.ui.rows)
  end

  defp to_int(v) when is_float(v), do: trunc(v)
  defp to_int(v) when is_integer(v), do: v
  defp to_int(v), do: trunc(v / 1)

  @impl true
  def terminate(_reason, _state) do
    MiniUI.show_cursor()
    :ok
  end
end

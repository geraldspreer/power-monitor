defmodule MiniUI do
  @moduledoc "Minimal terminal UI using ANSI escape codes."

  @enforce_keys [:cols, :rows]
  defstruct [:cols, :rows, padding_x: 0, padding_y: 0]

  @type t :: %__MODULE__{
    cols: pos_integer(),
    rows: pos_integer(),
    padding_x: non_neg_integer(),
    padding_y: non_neg_integer()
  }

  @home     "\e[H"
  @clear    "\e[2J\e[3J"
  @hide_cur "\e[?25l"
  @show_cur "\e[?25h"

  def new do
    # Get number of columns and rows in the terminal
    {cols, rows} =
      case {:io.columns(), :io.rows()} do
        {{:ok, c}, {:ok, r}} -> {c, r}
        {{:ok, c}, _}        -> {c, 24}
        _                    -> {80, 24}
      end

    %MiniUI{cols: cols, rows: rows}
  end

  def set_padding(%MiniUI{} = ui, x, y) do
    %{ui | padding_x: x, padding_y: y}
  end

  def clear(%MiniUI{} = ui) do
    IO.write([@clear, @home])
    home(ui)
    ui
  end

  def goto(%MiniUI{} = ui, x, y) do
    home(ui)
    down(y)
    right(x)
  end

  def home(%MiniUI{padding_x: px, padding_y: py}) do
    IO.write([
      @home,
      if(px > 0, do: "\e[#{px}C", else: []),
      if(py > 0, do: "\e[#{py}B", else: [])
    ])
  end

  def label(%MiniUI{} = ui, text, x, y) do
    goto(ui, x, y)
    IO.write(text)
    home(ui)
  end

  def hide_cursor, do: IO.write(@hide_cur)
  def show_cursor, do: IO.write(@show_cur)

  def left(n \\ 1), do: IO.write("\e[#{n}D")
  def right(n \\ 1), do: IO.write("\e[#{n}C")
  def down(n \\ 1), do: IO.write("\e[#{n}B")
  def up(n \\ 1), do: IO.write("\e[#{n}A")
end

defmodule MiniUI do
  @moduledoc "Minimal terminal UI using ANSI escape codes."

  @enforce_keys [:cols, :rows]
  defstruct [:cols, :rows]

  @type t :: %__MODULE__{
          cols: pos_integer(),
          rows: pos_integer()
        }

  @home "\e[H"
  @clear "\e[2J\e[3J"
  @hide_cursor "\e[?25l"
  @show_cursor "\e[?25h"

  def new do
    # hide_cursor()
    # Get number of columns and rows in the terminal
    {cols, rows} =
      case {:io.columns(), :io.rows()} do
        {{:ok, c}, {:ok, r}} -> {c, r}
        {{:ok, c}, _} -> {c, 24}
        _ -> {80, 24}
      end

    %MiniUI{cols: cols, rows: rows}
  end

  def goto(x, y) do
    home()
    down(y)
    right(x)
  end

  def label(text, x, y) do
    goto(x, y)
    IO.write(text)
  end

  def home(), do: IO.write(@home)
  def clear, do: IO.write([@clear, @home])
  def hide_cursor, do: IO.write(@hide_cursor)
  def show_cursor, do: IO.write(@show_cursor)
  def left(n \\ 1), do: IO.write("\e[#{n}D")
  def right(n \\ 1), do: IO.write("\e[#{n}C")
  def down(n \\ 1), do: IO.write("\e[#{n}B")
  def up(n \\ 1), do: IO.write("\e[#{n}A")
end

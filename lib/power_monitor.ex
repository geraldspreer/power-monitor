defmodule PowerMonitor do
  @moduledoc "Terminal power monitor for Fronius solar inverters."

  def main(args) do
    testing = "--test" in args
    debug   = "--debug" in args

    opts = [
      testing: testing,
      debug: debug
    ]

    {:ok, _pid} = PowerMonitor.Supervisor.start_link(opts)

    Process.sleep(:infinity)
  end
end


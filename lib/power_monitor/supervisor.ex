defmodule PowerMonitor.Supervisor do
  @moduledoc "Supervisor for PowerMonitor GenServers."
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    children = [
      {PowerMonitor.UIDisplay, [name: PowerMonitor.UIDisplay]},
      {PowerMonitor.DataFetcher, [name: PowerMonitor.DataFetcher, ui_server: PowerMonitor.UIDisplay] ++ args}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end

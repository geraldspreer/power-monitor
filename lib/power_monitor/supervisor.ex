defmodule PowerMonitor.Supervisor do
  @moduledoc "Supervisor for PowerMonitor GenServers."
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    testing = Keyword.get(args, :testing, false)

    data_fetcher_opts =
      [ui_server: PowerMonitor.UIDisplay] ++
        if(testing, do: [url: "http://localhost:8080/status/powerflow"], else: []) ++
        args

    children = [
      {PowerMonitor.UIDisplay, []},
      {PowerMonitor.DataFetcher, data_fetcher_opts}
    ]

    children =
      if testing do
        [
          {PowerMonitor.TestState, []},
          {PowerMonitor.TestServer, []}
        ] ++ children
      else
        children
      end

    Supervisor.init(children, strategy: :rest_for_one)
  end
end

defmodule PowerMonitor.TestState do
  @moduledoc "Agent for managing test server state."

  def start_link(_opts) do
    Agent.start_link(fn -> 0 end, name: :test_server_state)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def get do
    Agent.get(:test_server_state, fn state -> state end)
  rescue
    _ -> 0
  end

  def update(step) do
    Agent.update(:test_server_state, fn _ -> step end)
  rescue
    _ -> :ok
  end
end

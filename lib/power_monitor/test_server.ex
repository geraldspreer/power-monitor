defmodule PowerMonitor.TestServer do
  @moduledoc "Test HTTP server that simulates solar inverter responses."
  require Logger

  @port 8080

  def start_link(_opts) do
    Logger.info("Starting test server on http://localhost:#{@port}/status/powerflow")

    {:ok, _} =
      Plug.Cowboy.http(__MODULE__.Handler, [], port: @port)

    {:ok, self()}
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end
end

defmodule PowerMonitor.TestServer.Handler do
  @moduledoc "Plug handler for the test server."
  import Plug.Conn
  require Logger

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    case {conn.method, conn.path_info} do
      {"GET", ["status", "powerflow"]} ->
        step = get_test_step()
        data = make_data_set(step)
        new_step = if step >= 10, do: 0, else: step + 1
        store_test_step(new_step)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(data))

      _ ->
        conn
        |> send_resp(404, "Not found")
    end
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

  defp get_test_step do
    PowerMonitor.TestState.get()
  end

  defp store_test_step(step) do
    PowerMonitor.TestState.update(step)
  end
end


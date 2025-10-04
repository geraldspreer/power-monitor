defmodule PowerMonitor.MixProject do
  use Mix.Project

  def project do
    [
      app: :power_monitor,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: PowerMonitor]
    ]
  end

  def application do
    [extra_applications: [:logger, :inets]]
  end

  defp deps do
    [{:jason, "~> 1.4"}]
  end
end

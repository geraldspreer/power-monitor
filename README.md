# Power Monitor

Terminal-based power monitor for Fronius solar inverters. Displays live bar charts for autonomy, battery charge, consumption, PV output, and grid import/export.

### Screenshot

![Screenshot](docs/screenshot.png)

### Build

```sh
mix deps.get
mix escript.build
```

This produces a standalone `./power_monitor` escript.

### Run

```sh
./power_monitor              # Run the application
./power_monitor --test       # Cycle through test data (no network needed)
./power_monitor --debug      # Show raw values next to each bar
```

The inverter URL is hardcoded in `lib/power_monitor/data_fetcher.ex` as `@inverter_url`. Change it there before building.

### TODO

- [ ] Make the inverter vendor configurable
- [ ] Make this idiomatic Elixir, use message passing, like instead of using the `--test` parameter, send `.test` message to the runtime to enable **test mode**
- [ ] Instead of generating the test values, run a webserver with a test endpoint that provides the values
- [ ] Setup for Nerves project
- [ ] Add unit tests



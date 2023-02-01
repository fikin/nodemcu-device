# PID Simulator

Lua port of [pid-autotune](https://github.com/hirschmann/pid-autotune) plus some more code.

I've ported it as-is in order to have a baseline for testing algorithm changes.

Default json argument files are configured identically to examples from [pid-autotune](https://github.com/hirschmann/pid-autotune).

## Usage PID simulation

1. Edit `pid-simulation-args.json`
2. Run `./run-simulation.sh -pid`
3. Inspect output files in `out` dir
4. Plot the `out` results using `./plot-pid-results.py -pid`

## Usage PID Autotune

1. Edit `autotune-simulation-args.json`
2. Run `./run-simulation.sh -autotune`
3. Inspect output files in `out` dir
4. Plot the `out` results using `./plot-pid-results.py`

## Simulating different devices

Arguments feature `device_type` attribute which refers to `kettle` or `room`.

Kettle is the port from `pid-autotune`.

Room is a minor rework of the kettle model to simulate a room full with air, with circular volume geometry and walls thermal conductivity.

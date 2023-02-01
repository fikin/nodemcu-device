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

#!/bin/python3

import sys
import math
import json
import matplotlib.pyplot as plt


class obj(object):
    def __init__(self, dict_):
        self.__dict__.update(dict_)


def plot_simulations(args, simulations, title):
    lines = []
    fig, ax1 = plt.subplots()
    upper_limit = 0

    # Try to limit the y-axis to a more relevant area if possible
    for sim in simulations:
        m = max(sim.sensor_temps) + 1
        upper_limit = max(upper_limit, m)

    if upper_limit > args.setpoint:
        lower_limit = args.setpoint - (upper_limit - args.setpoint)
        ax1.set_ylim(lower_limit, upper_limit)

    # Create x-axis and first y-axis (temperature)
    ax1.plot()
    ax1.set_xlabel('time (s)')
    ax1.set_ylabel('temperature (°C)')
    ax1.grid(axis='y', linestyle=':', alpha=0.5)

    # Draw setpoint line
    lines += [plt.axhline(
        y=args.setpoint, color='r', linestyle=':', linewidth=0.9, label='setpoint')]

    # Create second y-axis (power)
    ax2 = ax1.twinx()
    ax2.set_ylabel('power (%)')

    # Plot temperature and output values
    i = 0
    for sim in simulations:
        color_cycle_idx = 'C' + str(i)
        lines += ax1.plot(
            sim.timestamps, sim.sensor_temps, color=color_cycle_idx,
            alpha=1.0, label='{0}: temp.'.format(sim.name))
        lines += ax2.plot(
            sim.timestamps, sim.outputs, '--', color=color_cycle_idx,
            linewidth=1, alpha=0.7, label='{0}: output'.format(sim.name))
        i += 1

    # Create legend
    labels = [l.get_label() for l in lines]
    offset = math.ceil((1 + len(simulations) * 2) / 3) * 0.05
    ax1.legend(lines, labels, loc=9, bbox_to_anchor=(
        0.5, -0.1 - offset), ncol=3)
    fig.subplots_adjust(bottom=0.2 + offset)

    # Set title
    plt.title(title)
    fig.canvas.manager.set_window_title(title)
    plt.show()


def readJson(fname: str) -> json:
    f = open(fname)
    data = json.load(f, object_hook=obj)
    f.close()
    return data

def getFName(arg):
    if arg == '-pid':
        return 'out/pid-simulation-results.json'
    elif arg == '-autotune':
        return 'out/autotune-simulation-results.json'
    else:
        print("Usage: [-pid|-autotune]")
        sys.exit(1)

def main():
    args = sys.argv[1:]
    if len(args) != 1:
        print("Usage: [-pid|-autotune]")
        sys.exit(1)
    data = readJson(getFName(args[0]))
    plot_simulations(data.args, data.sims, data.title)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import json
import sys

def plot(json):
    df = pd.read_json(json)
    fig, axs = plt.subplots(3, 2, sharex=True)
    df['profit'].plot(ax=axs[0][0], ylabel="Profit")
    df['cumsum_profit'] = df['profit'].cumsum()
    df['cumsum_profit'].plot(ax=axs[1][0], ylabel="Cumulative profit")
    df['served'].plot(ax=axs[2][0], ylabel="Served")
    df['popularity'].plot(ax=axs[0][1], ylabel="Popularity")
    df['avg_rating'].plot(ax=axs[1][1], ylabel="Average rating")
    df['avg_waiting_time'].plot(ax=axs[2][1], ylabel="Average waiting time")

    plt.xlabel("Days")

if __name__ == "__main__":
    plot(sys.stdin)
    plt.show()

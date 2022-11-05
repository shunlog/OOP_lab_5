#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import json

with open("out.json") as f:
    h = json.load(f)

def regular_plot(h):
    for key in h:
        df = pd.DataFrame(h[key])
        df['profit'].plot(label=key)

    plt.xlabel("Days")
    plt.ylabel("Daily profit")
    plt.legend(title="# of cooks")
    plt.show()

def cumulative_plot(h):
    for key in h:
        df = pd.DataFrame(h[key])
        df['profit'] = df['profit'].cumsum()
        df['profit'].plot(label=key)
    plt.xlabel("Days")
    plt.ylabel("Cumulative profit")
    plt.legend(title="# of cooks")
    plt.show()

regular_plot(h)
cumulative_plot(h)

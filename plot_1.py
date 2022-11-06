#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import json
import sys

def plot(json):
    df = pd.read_json(json)
    df['profit'].plot()

    plt.xlabel("Days")
    plt.ylabel("Daily profit")

if __name__ == "__main__":
    plot(sys.stdin)
    plt.show()

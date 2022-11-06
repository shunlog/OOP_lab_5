#!/usr/bin/env python3

import sys
import json
import pandas as pd
import matplotlib.pyplot as plt

data = json.load(sys.stdin)

fig, axs = plt.subplots(2, 1, sharex=True)

for key in data:
    df = pd.DataFrame(data[key])
    df['cumsum_profit'] = df['profit'].cumsum()
    df['profit'].plot(label=key, ax=axs[0], ylabel='Profit')
    df['cumsum_profit'].plot(label='', ax=axs[1], ylabel='Cumulative profit')
fig.legend(title="# of cooks")
plt.show()

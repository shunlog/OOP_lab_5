#!/usr/bin/env python3

import sys
import json
import pandas as pd
import matplotlib.pyplot as plt

data = json.load(sys.stdin)

cumulative = False

for key in data:
    df = pd.DataFrame(data[key])
    if cumulative:
        df['profit'] = df['profit'].cumsum()
    df['profit'].plot(label=key)
plt.xlabel("Days")
if cumulative:
    label = "Cumulative profit"
else:
    label = "Daily profit"
plt.ylabel(label)
plt.legend(title="# of cooks")
plt.show()

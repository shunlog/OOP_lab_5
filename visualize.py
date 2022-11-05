#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import json

with open("out.json") as f:
    h = json.load(f)

for key in h:
    df = pd.DataFrame(h[key])
    df['profit'].plot(label=key)

plt.xlabel("Days")
plt.ylabel("Daily profit")
plt.legend(title="# of cooks")
plt.show()

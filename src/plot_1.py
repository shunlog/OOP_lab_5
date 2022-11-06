#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import json
import sys

df = pd.read_json(sys.stdin)
df['profit'].plot()

plt.xlabel("Days")
plt.ylabel("Daily profit")
plt.legend(title="# of cooks")
plt.show()

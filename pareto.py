#!/usr/bin/env python3

def pareto(x, xm, a):
    if x >= xm:
        return (a * xm**a) / (x ** (a+1))
    else:
        return 0

def pop(rating):
    xm = 1
    a = 1.16
    return pareto(5.0+xm-rating, xm, a) / a

x = [1 + .1 * i for i in range(50)]
y = [pop(i) for i in x]

import matplotlib.pyplot as plt
# plt.plot(x, y)
# plt.show()

print(pop(1.0))
print(pop(5.0))

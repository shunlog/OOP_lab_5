# OOP Lab 5
## System evolution
One question we might ask is 
> How does the system evolve given some particular initial parameters?
Specifically, we can look at how the number of customers changes over time,
and compare different situations:
- it's a new restaurant and only a hanful of people know about it
- the restaurant recently got lots of recognition due to a very successful ad

So, given these initial conditions

``` python
DAYS=50
COOKS_COUNT=5
WAITERS_COUNT=1
TABLES_COUNT=20
INITIAL_POPULARITY=20000
COOK_SALARY=80.0
SHOW_STATS=0
```

Let's see how the model reacts to different values for `INITIAL_POPULARITY`.

For `INITIAL_POPULARITY=10`:
![](./img/new_slate.png)

For `INITIAL_POPULARITY=5000`:
![](./img/too_popular.png)

We can see that in every case, the system stabilizes pretty fast at the same popularity of about `180` and oscillates between `160` and `200`.

Of course, if we set `INITIAL_POPULARITY=180` right away, then the system doesn't evolve at all:
![](./img/regular_day.png)

## Optimal number of cooks
Another interesting question we might ask, is 
> What is the optimal number of cooks given a number of tables?

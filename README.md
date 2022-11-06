# OOP Lab 5

## Model execution
Given these initial conditions

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

`INITIAL_POPULARITY=10`
![](./img/new_slate.png)

`INITIAL_POPULARITY=180`
![](./img/regular_day.png)

`INITIAL_POPULARITY=5000`
![](./img/too_popular.png)

We can see that in every case, the system stabilizes pretty fast at the same popularity of about `180` and oscillates between `160` and `200`.

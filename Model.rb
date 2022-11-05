#!/usr/bin/env ruby

class Model
  attr_accessor :customers, :waiters, :cooks, :steps,
                :menu, :order_holder, :ledge, :served,
                :prng, :profit, :daily_metrics, :waiting_times,
                :logger

  WAITERS_COUNT = 1
  COOKS_COUNT = 5
  TABLES_COUNT = 20
  START_HOUR = 8
  END_HOUR = 20
  CLOSING_HOUR = 19
  INITIAL_RATING = 4.0
  INITIAL_RATINGS_COUNT = 10
  INITIAL_POPULARITY = 10 # number of customers daily
  COOK_SALARY = 80.0

  STATS = false
  START_TIME = Time.new(2022, mon=1, day=1, hour=8, min=0, sec=0)

  DailyMetrics = Struct.new(:profit, :served, :avg_rating, :avg_waiting_time, :popularity)
  Menu = Struct.new(:burgers, :fries, :drinks)
  MenuItem = Struct.new(:name, :prep_time, :price, :pm) #profit margin

  Burgers = [MenuItem.new("Fat Burger", 10, 4.99, 0.2)] +
            [MenuItem.new("Little Johnny", 8, 3.99, 0.2)]
  Fries = [MenuItem.new("Soggy Fries", 5, 1.99, 0.3)] +
          [MenuItem.new("Greasy Fingers", 6, 2.99, 0.3)]
  Drinks = [MenuItem.new("Overpriced tea", 1, 1.99, 0.9)] +
           [MenuItem.new("Overpriced drink", 1, 1.99, 0.9)]

  def initialize(cooks_count: COOKS_COUNT)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::WARN

    @prng = Random.new
    @ratings = [INITIAL_RATING] * INITIAL_RATINGS_COUNT
    @popularity = nil
    @menu = Menu.new(Burgers, Fries, Drinks)
    @daily_metrics = []

    @waiters = []
    WAITERS_COUNT.times do
      @waiters << Waiter.new(self)
    end
    @cooks = []
    @logger.info{cooks_count}
    cooks_count.times do
      @cooks << Cook.new(self)
    end

    new_day
  end

  def new_day
    @logger.info{"Starting day " + @daily_metrics.size.to_s}
    @steps = 0
    @order_holder = []
    @ledge = []
    @customers = []
    @waiting_times = []
    @profit = 0
    @served = 0
    unless @popularity
      @popularity = INITIAL_POPULARITY
    else
      @popularity += (avg_rating - 3) * @ratings.size * 1
    end
    @ratings = []
    @cooks.each do |c|
      c.new_day
    end
    @waiters.each do |w|
      w.new_day
    end
  end

  def wrap_up
    @customers.each do |c|
      c.wrap_up
    end
    store_daily_metrics
    new_day
  end

  def customer_appears
    unless @customers.size < TABLES_COUNT
      @popularity -= 1
      return
    end
    c = Customer.new(self)
    @customers << c
  end

  def closing_time
    (START_HOUR + @steps) > ((CLOSING_HOUR - START_HOUR) * 60)
  end

  def customers_appear
    if closing_time
      return
    end
    mean = @popularity.to_f / (wh * 60) # mean nr of customers per minute
    n = Distribution::Poisson.rng(mean)
    n.times do
      customer_appears
    end
  end

  def step
    customers_appear
    @waiters.each do |w|
      w.step
    end
    @customers.each do |c|
      c.step
    end
    @cooks.each do |c|
      c.step
    end
    print_stats
    @steps += 1
  end

  def avg_waiting_time
    if @waiting_times.size == 0
      return 0
    end
    (@waiting_times.sum.to_f / @waiting_times.size).round
  end

  def avg_rating
    if @ratings.size == 0
      return 0
    end
    (@ratings.sum.to_f / @ratings.size).round(1)
  end

  def store_daily_metrics
    profit = @profit - (@cooks.size * COOK_SALARY)
    @daily_metrics << DailyMetrics.new(profit, @served, avg_rating, avg_waiting_time, @popularity)
  end

  def run_a_day
    (wh*60).times do
      step
    end
    wrap_up
  end

  def day
    @steps.div(wh * 60)
  end

  def wh
    END_HOUR - START_HOUR
  end

  def time
    t = START_TIME
    unless day == 0
      t += @steps.remainder(day) * 60
    else
      t += @steps * 60
    end
    t += day * 60 * 60 * 24
    t.strftime "%H:%M"
  end

  def rate(rating)
    @ratings << rating
  end

  def print_stats
    unless STATS
      return
    end

    rows = [
      ["Customers", "", @customers.size.to_s],
      ["", "Choosing order", @customers.filter{ |c| c.state == :choosing_order}.size.to_s],
      ["", "Waiting waiter", @customers.filter{ |c| c.state == :waiting_waiter}.size.to_s],
      ["", "Waiting food", @customers.filter{ |c| c.state == :waiting_food}.size.to_s],
      ["", "Eating", @customers.filter{ |c| c.state == :eating}.size.to_s],
      ["", "Waiting check", @customers.filter{ |c| c.state == :waiting_check}.size.to_s],

      ["Waiters", "", @waiters.size.to_s],
      ["", "Waiting", @waiters.filter{ |c| c.state == :waiting}.size.to_s],
      ["", "Cleaning table", @waiters.filter{ |c| c.state == :cleaning_table}.size.to_s],

      ["Cooks", "", @cooks.size.to_s],
      ["", "Waiting", @cooks.filter{ |c| c.state == :waiting}.size.to_s],
      ["", "Cooking", @cooks.filter{ |c| c.state == :cooking}.size.to_s],

      ["Tables", "", TABLES_COUNT.to_s],
      ["", "Free", (TABLES_COUNT - @customers.size).to_s],

      ["Served", "", @served.to_s],

      ["Profit", "", @profit.round(2).to_s],
      ["Rating", "", avg_rating.to_s],
    ]

    w1 = 10
    w2 = 20
    w3 = 7
    ws = w1 + w2 + w3
    puts "+" + "-"*(ws+2) + "+"
    puts "|" + "Time: #{time}, Day: #{day}".center(ws+2) + "|"
    puts "+" + "-"*(ws+2) + "+"
    rows.each do |row|
      puts "|#{row[0].ljust(w1)}|#{row[1].ljust(w2)}|#{row[2].rjust(w3)}|"
    end
    puts "+" + "-"*(ws+2) + "+"
  end

  def print_daily_metrics
    @daily_metrics.each do |m|
      print m.profit.round(2), "\t", m.served, "\t", m.avg_rating, "\t",
            m.avg_waiting_time, "\t", m.popularity, "\n"
    end
  end

  def daily_metrics_hash
    @daily_metrics.map{ |e| e.to_h }
  end

  def json_daily_metrics
    hashified = @daily_metrics.map{ |e| e.to_h }
    JSON.generate(hashified)
  end
end

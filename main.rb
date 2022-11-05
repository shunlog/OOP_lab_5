#!/usr/bin/env ruby
require 'logger'

STATS = true

class Order
  attr_accessor :customer

  def initialize(customer, items)
    @customer = customer
    @items = items
  end

  def prep_time
    @items.sum() { |item| item.prep_time}
  end

  def cost
    @items.sum() { |item| item.price}
  end
end

class Agent
  attr_accessor :state

  def initialize(model)
    @model = model
  end

  def step
  end
end

class Customer < Agent
  CHOOSING_ORDER_TIME = 5
  EATING_TIME = 30

  def initialize(model)
    super
    @state = :choosing_order
    @state_start = @model.steps
    @waiting_time = 0
    @order = nil
  end

  def decide_order
    items = []
    # one burger
    items += [@model.menu.burgers.sample]
    # one or two fries
    n_fries = @model.prng.rand(2) + 1
    n_fries.times do
      items += [@model.menu.fries.sample]
    end
    # zero or one drinks
    n_drinks = @model.prng.rand(2)
    n_drinks.times do
      items += [@model.menu.drinks.sample]
    end
    @order = Order.new(self, items)
    @state = :waiting_waiter
  end

  def order
    @waiting_time += @model.steps - @state_start
    @state = :waiting_food
    return @order
  end

  def serve
    @waiting_time += @model.steps - @state_start
    @state = :eating
    @state_start = @model.steps
  end

  def finish_eating
    @state = :waiting_check
    @state_start = @model.steps
  end

  def pay
    @waiting_time += @model.steps - @state_start
    @model.waiting_times << @waiting_time
    return @order.cost
  end

  def wrap_up
    @model.rate(1)
    @model.served += 1
    @model.waiting_times << @waiting_time
  end

  def rate
    ratio = @waiting_time.to_f / @order.prep_time
    if ratio < 2.5 then
      stars = 5
    elsif ratio < 3 then
      stars = 4
    elsif ratio < 5 then
      stars = 3
    elsif ratio < 7 then
      stars = 2
    else
      stars = 1
    end
    @model.rate(stars)
  end

  def step
    if @state == :choosing_order &&
       @model.steps - @state_start >= CHOOSING_ORDER_TIME
      decide_order
      return
    end
    if @state == :eating &&
       @model.steps - @state_start >= EATING_TIME
      finish_eating
      return
    end
  end
end

class Waiter < Agent
  Order = Struct.new(:customer, :items)
  CLEANING_TIME = 2

  def initialize(model)
    super
    @state = :waiting
    @orders = []
  end

  def new_day
    @state = :waiting
    @orders = []
  end

  def customer_waiting_ordering
    customers_waiting = @model.customers.select { |c|
      c.state == :waiting_waiter
    }
    unless customers_waiting.size == 0
      next_customer = customers_waiting[0]
      return next_customer
    end
    return nil
  end

  def customer_waiting_check
    customers_waiting = @model.customers.select { |c|
      c.state == :waiting_check
    }
    unless customers_waiting.size == 0
      next_customer = customers_waiting[0]
      return next_customer
    end
    return nil
  end

  def take_order(customer)
    @orders << customer.order
  end

  def leave_orders
    @orders.each { |o|
      @model.order_holder << o
    }
    @orders = []
  end

  def serve_an_order
    order = @model.ledge.pop
    order.customer.serve
  end

  def bill_customer(customer)
    s = customer.pay
    customer.rate
    @model.profit += s
    @model.served += 1
    @model.customers.delete(customer)
    clean_table
  end

  def clean_table
    @state = :cleaning_table
    @state_start = @model.steps
  end

  def step
    if @state == :cleaning_table &&
       @model.steps - @state_start >= CLEANING_TIME
      @state = :waiting
    end
    if @state == :waiting
      if customer_waiting_check
        bill_customer(customer_waiting_check)
        return
      end

      if customer_waiting_ordering
        take_order(customer_waiting_ordering)
        return
      end

      unless @orders.empty?
        leave_orders
        return
      end

      unless @model.ledge.empty?
        serve_an_order
        return
      end
    end
  end
end

class Cook < Agent
  def initialize(model)
    super
    @order = nil
    @state = :waiting
  end

  def new_day
    @state = :waiting
    @order = nil
  end

  def check_order_holder
    if @model.order_holder.empty?
      return
    end
    @order = @model.order_holder.pop
    @state = :cooking
    @state_start = @model.steps
  end

  def finish_order
    @state = :waiting
    @model.ledge << @order
    @order = nil
  end

  def step
    if @state == :waiting
      check_order_holder
    end
    if @state == :cooking &&
       @model.steps - @state_start >= @order.prep_time
      finish_order
    end
  end
end

class Model
  attr_accessor :customers, :waiters, :cooks, :steps,
                :menu, :order_holder, :ledge, :served,
                :prng, :profit, :daily_metrics, :waiting_times,
                :logger

  WAITERS_COUNT = 10
  COOKS_COUNT = 20
  TABLES_COUNT = 1000
  START_HOUR = 8
  END_HOUR = 20
  CLOSING_HOUR = 19
  INITIAL_RATING = 4.0
  INITIAL_RATINGS_COUNT = 10
  INITIAL_POPULARITY = 10 # number of customers daily

  START_TIME = Time.new(2022, mon=1, day=1, hour=8, min=0, sec=0)

  DailyMetrics = Struct.new(:profit, :served, :avg_rating, :avg_waiting_time)
  Menu = Struct.new(:burgers, :fries, :drinks)
  MenuItem = Struct.new(:name, :prep_time, :price, :pm) #profit margin

  Burgers = [MenuItem.new("Fat Burger", 10, 4.99, 0.2)] +
            [MenuItem.new("Little Johnny", 8, 3.99, 0.2)]
  Fries = [MenuItem.new("Soggy Fries", 5, 1.99, 0.3)] +
          [MenuItem.new("Greasy Fingers", 6, 2.99, 0.3)]
  Drinks = [MenuItem.new("Overpriced tea", 1, 1.99, 0.9)] +
           [MenuItem.new("Overpriced drink", 1, 1.99, 0.9)]

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG

    @prng = Random.new
    @ratings = [INITIAL_RATING] * INITIAL_RATINGS_COUNT
    @popularity = INITIAL_POPULARITY
    @menu = Menu.new(Burgers, Fries, Drinks)
    @daily_metrics = []

    @waiters = []
    WAITERS_COUNT.times do
      @waiters << Waiter.new(self)
    end
    @cooks = []
    COOKS_COUNT.times do
      @cooks << Cook.new(self)
    end

    new_day
  end

  def new_day
    @steps = 0
    @order_holder = []
    @ledge = []
    @customers = []
    @waiting_times = []
    @profit = 0
    @served = 0
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
    10.times do
      customer_appears
    end
    # if @prng.rand(1) == 0 && @customers.size < TABLES_COUNT
    #   customer_appears
    # end
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
    @daily_metrics << DailyMetrics.new(@profit, @served, avg_rating, avg_waiting_time)
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
      print m.profit.round(2), "\t", m.served, "\t", m.avg_rating, "\t", m.avg_waiting_time, "\n"
    end
  end

end

model = Model.new
10.times do
  model.run_a_day
end

model.print_daily_metrics

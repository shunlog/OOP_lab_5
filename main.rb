#!/usr/bin/env ruby
DEBUG = false

def log(s)
  unless DEBUG
    return
  end
  puts ">>> " + s
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
    @state_start = model.steps
    @order = nil
  end

  def decide_order
    @order = []
    # one burger
    @order += [@model.menu.burgers.sample]
    # one or two fries
    n_fries = @model.prng.rand(2) + 1
    n_fries.times do
      @order += [@model.menu.fries.sample]
    end
    # zero or one drinks
    n_drinks = @model.prng.rand(2)
    n_drinks.times do
      @order += [@model.menu.drinks.sample]
    end
    @state = :waiting_waiter
  end

  def order
    @state = :waiting_food
    return @order
  end

  def serve
    @state = :eating
    @state_start = @model.steps
  end

  def finish_eating
    @state = :waiting_check
  end

  def pay
    sum = @order.sum { |item| item.price * item.pm}
    return sum
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

  def wrap_up
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
    items = customer.order
    order = Order.new(customer, items)
    @orders << order
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

  def conduct_payment(customer)
    s = customer.pay
    @model.profit += s
    @model.served += 1
    @model.customers.delete(customer)
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
        conduct_payment(customer_waiting_check)

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

  def wrap_up
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

  def prep_time(order)
    # how long an order (list) will take to cook
    order.items.sum() { |item| item.prep_time}
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
       @model.steps - @state_start >= prep_time(@order)
      finish_order
    end
  end
end

class Model
  attr_accessor :customers, :waiters, :cooks, :steps,
                :menu, :order_holder, :ledge, :served,
                :prng, :profit, :daily_metrics

  NR_WAITERS = 2
  NR_COOKS = 2
  NR_TABLES = 10
  START_HOUR = 8
  END_HOUR = 20

  DailyMetrics = Struct.new(:profit, :served)

  Menu = Struct.new(:burgers, :fries, :drinks)
  MenuItem = Struct.new(:name, :prep_time, :price, :pm) #profit margin
  Burgers = [MenuItem.new("Fat Burger", 10, 4.99, 0.2)] +
            [MenuItem.new("Little Johnny", 8, 3.99, 0.2)]
  Fries = [MenuItem.new("Soggy Fries", 5, 1.99, 0.3)] +
          [MenuItem.new("Greasy Fingers", 6, 2.99, 0.3)]
  Drinks = [MenuItem.new("Overpriced tea", 1, 1.99, 0.9)] +
           [MenuItem.new("Overpriced drink", 1, 1.99, 0.9)]

  def initialize
    @prng = Random.new
    @steps = 0
    @profit = 0
    @menu = Menu.new(Burgers, Fries, Drinks)
    @order_holder = []
    @ledge = []
    @served = 0
    @daily_metrics = []

    @customers = []
    @waiters = []
    NR_WAITERS.times do
      @waiters << Waiter.new(self)
    end
    @cooks = []
    NR_COOKS.times do
      @cooks << Cook.new(self)
    end

    @start_time = Time.new(2022, mon=1, day=1, hour=8, min=0, sec=0)
  end

  def customer_appears
    c = Customer.new(self)
    @customers << c
  end

  def customers_appear
    if @prng.rand(10) == 0 && @customers.size < NR_TABLES
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

  def store_daily_metrics
    @daily_metrics << DailyMetrics.new(@profit, @served)
    @profit = 0
    @served = 0
  end

  def wrap_up
    @order_holder = []
    @ledge = []
    @customers = []
    @cooks.each do |c|
      c.wrap_up
    end
    @waiters.each do |w|
      w.wrap_up
    end
    store_daily_metrics
  end

  def run_a_day
    (wh*60).times do
      step
    end
    wrap_up
    step
  end

  def day
    @steps.div(wh * 60)
  end

  def wh
    END_HOUR - START_HOUR
  end

  def time
    t = @start_time
    unless day == 0
      t += @steps.remainder(day) * 60
    else
      t += @steps * 60
    end
    t += day * 60 * 60 * 24
    t.strftime "%H:%M"
  end

  def print_stats
    unless DEBUG
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

      ["Tables", "", NR_TABLES.to_s],
      ["", "Free", (NR_TABLES - @customers.size).to_s],

      ["Served", "", @served.to_s],

      ["Profit", "", @profit.round(2).to_s],
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
      print m.profit.round(2), "\t", m.served, "\n"
    end
  end

end

model = Model.new
10.times do
  model.run_a_day
end

model.print_daily_metrics

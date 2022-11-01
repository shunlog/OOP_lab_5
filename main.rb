#!/usr/bin/env ruby
require 'table_print'
DEBUG = true

def log(s)
  if DEBUG
    puts ">>> " + s
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

class Client < Agent
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
  Order = Struct.new(:client, :items)
  CLEANING_TIME = 2

  def initialize(model)
    super
    @state = :waiting
    @orders = []
  end

  def client_waiting_ordering
    clients_waiting = @model.clients.select { |c|
      c.state == :waiting_waiter
    }
    unless clients_waiting.size == 0
      next_client = clients_waiting[0]
      return next_client
    end
    return nil
  end

  def client_waiting_check
    clients_waiting = @model.clients.select { |c|
      c.state == :waiting_check
    }
    unless clients_waiting.size == 0
      next_client = clients_waiting[0]
      return next_client
    end
    return nil
  end

  def take_order(client)
    items = client.order
    order = Order.new(client, items)
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
    order.client.serve
  end

  def conduct_payment(client)
    s = client.pay
    @model.profit += s
    @model.served += 1
    @model.clients.delete(client)
    @state = :cleaning_table
    @state_start = @model.steps
  end

  def step
    if @state == :cleaning_table &&
       @model.steps - @state_start >= CLEANING_TIME
      @state = :waiting
    end
    if @state == :waiting
      if client_waiting_check
        conduct_payment(client_waiting_check)

        return
      end

      if client_waiting_ordering
        take_order(client_waiting_ordering)
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
  attr_accessor :clients, :waiters, :cooks, :steps,
                :menu, :order_holder, :ledge, :served,
                :prng, :profit

  NR_WAITERS = 2
  NR_COOKS = 2
  NR_TABLES = 10

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

    @clients = []
    @waiters = []
    NR_WAITERS.times do
      @waiters << Waiter.new(self)
    end
    @cooks = []
    NR_COOKS.times do
      @cooks << Cook.new(self)
    end

    @start_time = Time.new(2022, mon=1, day=1, hour=8, min=0, sec=0)
    @start_hour = 8
    @end_hour = 20
  end

  def client_appears
    c = Client.new(self)
    @clients << c
  end

  def clients_appear
    if @prng.rand(10) == 0 && @clients.size < NR_TABLES
      client_appears
    end
  end

  def step
    clients_appear
    @waiters.each do |w|
      w.step
    end
    @clients.each do |c|
      c.step
    end
    @cooks.each do |c|
      c.step
    end
    dashboard
    @steps += 1
  end

  def day
    @steps.div(wh * 60)
  end

  def wh
    @end_hour - @start_hour
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

  def dashboard
    rows = [
      ["Clients", "", @clients.size.to_s],
      ["", "Choosing order", @clients.filter{ |c| c.state == :choosing_order}.size.to_s],
      ["", "Waiting waiter", @clients.filter{ |c| c.state == :waiting_waiter}.size.to_s],
      ["", "Waiting food", @clients.filter{ |c| c.state == :waiting_food}.size.to_s],
      ["", "Eating", @clients.filter{ |c| c.state == :eating}.size.to_s],
      ["", "Waiting check", @clients.filter{ |c| c.state == :waiting_check}.size.to_s],

      ["Waiters", "", @waiters.size.to_s],
      ["", "Waiting", @waiters.filter{ |c| c.state == :waiting}.size.to_s],
      ["", "Cleaning table", @waiters.filter{ |c| c.state == :cleaning_table}.size.to_s],

      ["Cooks", "", @cooks.size.to_s],
      ["", "Waiting", @cooks.filter{ |c| c.state == :waiting}.size.to_s],
      ["", "Cooking", @cooks.filter{ |c| c.state == :cooking}.size.to_s],

      ["Tables", "", NR_TABLES.to_s],
      ["", "Free", (NR_TABLES - @clients.size).to_s],

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
end

model = Model.new

(model.wh*60+1).times do
  model.step
end

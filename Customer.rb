#!/usr/bin/env ruby

require_relative 'Agent'

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

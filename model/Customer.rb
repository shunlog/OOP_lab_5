#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'Agent'

class Customer < Agent
  CHOOSING_ORDER_TIME = 5
  EATING_TIME = 30

  def initialize(model)
    super
    change_state(:choosing_order)
    @waiting_time = 0
    @order = nil
  end

  def to_s
    "Customer #{self.object_id}"
  end

  def change_state(state)
    @state_start = @model.steps
    @state = state
    if state == :choosing_order
      @model.logger.info {"#{self} entered restaurant."}
    elsif state == :waiting_waiter
      @model.logger.info {"#{self} decided what to order."}
    elsif state == :waiting_food
      @waiting_time += @model.steps - @state_start
    elsif state == :eating
      @waiting_time += @model.steps - @state_start
    elsif state == :waiting_check
      @model.logger.info {"#{self} finished eating and asked for the check."}
    elsif state == :exiting
      @waiting_time += @model.steps - @state_start
      @model.waiting_times << @waiting_time
    end
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
    change_state(:waiting_waiter)
  end

  def order
    change_state(:waiting_food)
    @order
  end

  def serve
    change_state(:eating)
  end

  def finish_eating
    change_state(:waiting_check)
  end

  def pay
    change_state(:exiting)
    @order.cost
  end

  def wrap_up
    @model.rate(1)
    @model.served += 1
    @model.waiting_times << @waiting_time
  end

  def rate
    ratio = @waiting_time.to_f / @order.prep_time
    stars = if ratio < 2.5
              5
            elsif ratio < 3
              4
            elsif ratio < 5
              3
            elsif ratio < 7
              2
            else
              1
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
      nil
    end
  end
end

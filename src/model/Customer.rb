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
    "Customer #{object_id}"
  end

  def change_state(state)
    case state
    when :choosing_order
      @model.notify(:log, "#{self} entered restaurant." )
    when :waiting_waiter
      @model.notify(:log, "#{self} decided what to order." )
    when :waiting_food
      @waiting_time += state_duration
    when :eating
      @waiting_time += state_duration
    when :waiting_check
      @model.notify(:log, "#{self} finished eating and asked for the check." )
    when :exiting
      @waiting_time += state_duration
      @model.waiting_times << @waiting_time
    end
    @state_start = @model.steps
    @state = state
  end

  def decide_order
    items = []
    [1].sample.times do
      items += [@model.menu.burgers.sample]
    end
    [1,2].sample.times do
      items += [@model.menu.fries.sample]
    end
    [0,1].sample.times do
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

  def wrap_up
    change_state(:exiting)
    @model.rate(1)
  end

  def rate
    ratio = @waiting_time.to_f / @order.prep_time
    stars = if ratio < 1.5
              5
            elsif ratio < 2
              4
            elsif ratio < 2.5
              3
            elsif ratio < 3
              2
            else
              1
            end
    @model.rate(stars)
  end

  def step
    if @state == :choosing_order && state_duration >= CHOOSING_ORDER_TIME
      decide_order
    elsif @state == :eating && state_duration >= EATING_TIME
      finish_eating
    end
  end
end

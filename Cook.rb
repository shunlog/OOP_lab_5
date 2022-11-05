#!/usr/bin/env ruby

require_relative 'Agent'

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

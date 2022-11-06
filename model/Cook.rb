#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'Agent'

class Cook < Agent
  def initialize(model)
    super
    new_day
  end

  def to_s
    "Cook #{self.object_id}"
  end

  def new_day
    change_state(:waiting)
    @order = nil
  end

  def change_state(state)
    if state == :waiting
      if @state == :cooking
        @model.logger.info {"#{self} finished cooking #{@order}."}
      end
    elsif state == :cooking
      @model.logger.info {"#{self} started cooking #{@order}."}
    end
    @state_start = @model.steps
    @state = state
  end

  def check_order_holder
    return if @model.order_holder.empty?

    @order = @model.order_holder.pop
    change_state(:cooking)
  end

  def finish_order
    change_state(:waiting)
    @model.ledge << @order
    @order = nil
  end

  def step
    check_order_holder if @state == :waiting
    if @state == :cooking &&
       @model.steps - @state_start >= @order.prep_time
      finish_order
    end
  end
end

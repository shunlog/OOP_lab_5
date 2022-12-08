#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'Agent'

class Cook < Agent
  def initialize(model)
    super
    start_day
  end

  def to_s
    "Cook #{object_id}"
  end

  def start_day
    change_state(:waiting)
    @order = nil
  end

  def change_state(state)
    case state
    when :waiting
      @model.notify(:log, "#{self} finished cooking #{@order}." ) if @state == :cooking
    when :cooking
      @model.notify(:log, "#{self} started cooking #{@order}." )
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
    if @state == :waiting
      check_order_holder
    elsif @state == :cooking && state_duration >= @order.prep_time
      finish_order
    end
  end
end

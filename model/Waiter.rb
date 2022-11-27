#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'Agent'

class Waiter < Agent
  Order = Struct.new(:customer, :items)
  CLEANING_TIME = 5

  def initialize(model)
    super
    start_day
  end

  def to_s
    "Waiter #{object_id}"
  end

  def start_day
    change_state(:waiting)
    @orders = []
  end

  def customer_waiting_ordering
    customers_waiting = @model.customers.select do |c|
      c.state == :waiting_waiter
    end
    unless customers_waiting.size.zero?
      next_customer = customers_waiting[0]
      return next_customer
    end
    nil
  end

  def customer_waiting_check
    customers_waiting = @model.customers.select do |c|
      c.state == :waiting_check
    end
    unless customers_waiting.size.zero?
      next_customer = customers_waiting[0]
      return next_customer
    end
    nil
  end

  def take_order(customer)
    @orders << customer.order
    @model.logger.info { "#{self} took #{customer}'s order." }
  end

  def leave_orders
    @orders.each do |o|
      @model.order_holder << o
    end
    @model.logger.info { "#{self} left #{@orders.size} orders in the order holder." }
    @orders = []
  end

  def serve_an_order
    order = @model.ledge.pop
    order.customer.serve
    @model.logger.info { "#{self} served order to #{order.customer}." }
  end

  def bill_customer(customer)
    customer.rate
    @model.profit += customer.order.profit
    @model.served += 1
    @model.customers.delete(customer)
    @model.logger.info { "#{self} billed #{customer}." }
    clean_table
  end

  def clean_table
    change_state(:cleaning_table)
  end

  def change_state(state)
    case state
    when :waiting
      @model.logger.info { "#{self} finished cleaning the table." } if @state == :cleaning_table
    when :cleaning_table
      @model.logger.info { "#{self} started cleaning the table." }
    end
    @state_start = @model.steps
    @state = state
  end

  def step
    if @state == :cleaning_table &&
       state_duration >= CLEANING_TIME
      change_state(:waiting)
    elsif @state == :waiting && customer_waiting_check
      bill_customer(customer_waiting_check)
    elsif @state == :waiting && customer_waiting_ordering
      take_order(customer_waiting_ordering)
    elsif @state == :waiting && !@orders.empty?
      leave_orders
    elsif @state == :waiting && !@model.ledge.empty?
      serve_an_order
    end
  end
end

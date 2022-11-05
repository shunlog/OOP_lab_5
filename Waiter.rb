#!/usr/bin/env ruby

require_relative 'Agent'

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

#!/usr/bin/env ruby
# frozen_string_literal: true

class Order
  attr_accessor :customer

  def initialize(customer, items)
    @customer = customer
    @items = items
  end

  def to_s
    "Order #{object_id}"
  end

  def prep_time
    @items.sum(&:prep_time)
  end

  def profit
    @items.sum { |i| i.price * i.profit_margin }
  end
end

#!/usr/bin/env ruby
# frozen_string_literal: true

class Order
  attr_accessor :customer

  def initialize(customer, items)
    @customer = customer
    @items = items
  end

  def prep_time
    @items.sum(&:prep_time)
  end

  def cost
    @items.sum(&:price)
  end
end

#!/usr/bin/env ruby

class Order
  attr_accessor :customer

  def initialize(customer, items)
    @customer = customer
    @items = items
  end

  def prep_time
    @items.sum() { |item| item.prep_time}
  end

  def cost
    @items.sum() { |item| item.price}
  end
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'Model'
require_relative 'Order'
require_relative 'Customer'
require_relative 'Cook'
require_relative 'Waiter'

def run_for_varying_cooks(min_cooks: 1, max_cooks: 7, days: 10)
  hash = {}
  (min_cooks..max_cooks).step do |i|
    model = Model.new(cooks_count: i)
    days.times do
      model.run_a_day
    end
    hash[i.to_s] = model.daily_metrics_hash
  end
  hash
end

hash = run_for_varying_cooks
puts JSON.generate(hash)

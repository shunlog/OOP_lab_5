#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'Model'
require_relative 'Order'
require_relative 'Customer'
require_relative 'Cook'
require_relative 'Waiter'

model = Model.new()
100.times do
  model.run_a_day
end
puts model.json_daily_metrics

#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'Model'

model = Model.new()
100.times do
  model.run_a_day
end

puts model.json_daily_metrics

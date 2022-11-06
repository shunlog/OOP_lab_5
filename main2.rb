#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'model/Model'

min_cooks = ENV['MIN_COOKS'].to_i
max_cooks = ENV['MAX_COOKS'].to_i
interval = ENV['COOKS_INTERVAL'].to_i
days = ENV['DAYS'].to_i

hash = {}
(min_cooks..max_cooks).step(interval) do |i|
  model = Model.new(cooks_count: i,
                    waiters_count: ENV['WAITERS_COUNT'].to_i,
                    tables_count: ENV['TABLES_COUNT'].to_i,
                    initial_popularity: ENV['INITIAL_POPULARITY'].to_i,
                    cook_salary: ENV['COOK_SALARY'].to_f)
  days.times do
    model.run_a_day
  end
  hash[i.to_s] = model.daily_metrics_hash
end

puts JSON.generate(hash)

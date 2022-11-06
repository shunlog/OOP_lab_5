#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'model/Model'

model = Model.new(show_stats: true,
                  cooks_count: 1,
                  waiters_count: 1,
                  tables_count: 10000,
                  initial_popularity: 100000,
                  stats_frequency: 120,
                  logger_level: Logger::INFO)

days = 2

days.times do
  model.run_a_day
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'model/Model'
require_relative 'View'

model = Model.new(show_stats: false,
                  cooks_count: 1,
                  waiters_count: 1,
                  tables_count: 10,
                  initial_popularity: 10,
                  stats_frequency: 120,
                  logger_level: Logger::ERROR)
view = TUIView.new(model)

loop do
  model.step
  view.print
  sleep(0.001)
end

#!/usr/bin/env ruby

require_relative 'model/Model'

model = Model.new(show_stats: true)
10.times do
  model.run_a_day
end

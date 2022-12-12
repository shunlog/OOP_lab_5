#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'model/Model'
require_relative 'View'
require_relative 'Controller'

model = Model.new(show_stats: false,
                  cooks_count: 1,
                  waiters_count: 1,
                  tables_count: 10,
                  initial_popularity: 10,
                  stats_frequency: 120)
contr = TUIController.new(model)
view = TUIView.new(model, contr)

view.run

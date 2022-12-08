#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'model/Model'
require_relative 'View'

model = Model.new(show_stats: false,
                  cooks_count: 1,
                  waiters_count: 1,
                  tables_count: 10,
                  initial_popularity: 10,
                  stats_frequency: 120)
view = TUIView.new(model)

require 'ffi-ncurses'
include FFI::NCurses

# cbreak
# noecho
timeout(0) # delay in milliseconds

def KEY(ch)
  ch[0].ord
end

play = true

loop do
  ch = getch
  if ch == KEY("q")
    break
  elsif ch == KEY(" ")
    play = !play
  end

  if play or ch == KEY("n")
    model.step
    view.print
  end
  sleep(0.001)
end

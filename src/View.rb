#!/usr/bin/env ruby

require 'ffi-ncurses'
include FFI::NCurses

class ClockView
  attr_reader :text
  W = 32
  H = 11
  M = 1

  def initialize(model, time=0, y: 0, x: 0)
    @model = model
    @time = time
    model.add_observer(:time, self.method(:update))
    @win = newwin(H, W, y, x)
    box(@win, 0, 0)
    @iwin = derwin(@win, H-2*M, W-2*M, M, M)
    scrollok @iwin, true
  end

  def update(time)
    clock = %x(figlet #{@model.time})
    @text = "Time:\n#{clock}"
  end

  def print()
    werase(@iwin)
    mvwaddstr(@iwin, 0, 0, @text)
    wrefresh(@win)
    wrefresh(@iwin)
  end
end

class DateView
  attr_reader :text
  W = 20
  H = 11
  M = 1
  def initialize(model, date=1, y: 0, x: 0)
    @model = model
    update(date)
    model.add_observer(:date, self.method(:update))

    @win = newwin(H, W, y, x)
    box(@win, 0, 0)
    @iwin = derwin(@win, H-2*M, W-2*M, M, M)
    scrollok @iwin, true
  end

  def update(date)
    fig = %x(figlet #{date})
    @text = "Day:\n#{fig}"
  end

  def print()
    werase(@iwin)
    mvwaddstr(@iwin, 0, 0, @text)
    wrefresh(@win)
    wrefresh(@iwin)
  end
end

class LogsView
  attr_reader :text
  W = 80
  H = 34
  M = 2
  def initialize(model, y: 0, x: 0)
    @model = model
    model.add_observer(:log, self.method(:update))

    @win = newwin(H, W, y, x)
    box(@win, 0, 0)
    @iwin = derwin(@win, H-2*M, W-2*M, M, M)
    scrollok @iwin, true
  end

  def update(message)
    @text = "> Day #{@model.day}, #{@model.time}: #{message}\n"
  end

  def print()
    waddstr(@iwin, @text)
    wrefresh(@win)
    wrefresh(@iwin)
    @text = ""
  end
end

class DashboardView
  attr_reader :text, :model

  W = 46
  H = 26
  M = 2
  def initialize(model, y: 0, x: 0)
    @model = model
    model.add_observer(:dashboard, self.method(:update))

    @win = newwin(H, W, y, x)
    box(@win, 0, 0)
    @iwin = derwin(@win, H-2*M, W-2*M, M, M)
    scrollok @iwin, true
  end

  def update()
    @text = "Dashboard:\n"

    rows = [
      ['People', '', @model.agents.size.to_s],
      ['Customers', '', @model.customers.size.to_s],
      ['', 'Choosing order', @model.customers.filter { |c| c.state == :choosing_order }.size.to_s],
      ['', 'Waiting waiter', @model.customers.filter { |c| c.state == :waiting_waiter }.size.to_s],
      ['', 'Waiting food', @model.customers.filter { |c| c.state == :waiting_food }.size.to_s],
      ['', 'Eating', @model.customers.filter { |c| c.state == :eating }.size.to_s],
      ['', 'Waiting check', @model.customers.filter { |c| c.state == :waiting_check }.size.to_s],

      ['Waiters', '', @model.waiters.size.to_s],
      ['', 'Waiting', @model.waiters.filter { |c| c.state == :waiting }.size.to_s],
      ['', 'Cleaning table', @model.waiters.filter { |c| c.state == :cleaning_table }.size.to_s],

      ['Cooks', '', @model.cooks.size.to_s],
      ['', 'Waiting', @model.cooks.filter { |c| c.state == :waiting }.size.to_s],
      ['', 'Cooking', @model.cooks.filter { |c| c.state == :cooking }.size.to_s],

      ['Tables', '', @model.tables_count.to_s],
      ['', 'Free', (@model.tables_count - @model.customers.size).to_s],

      ['Served', '', @model.served.to_s],

      ['Profit', '', @model.profit.round(2).to_s],
      ['Rating', '', @model.avg_rating.to_s]
    ]
    w1 = 10
    w2 = 20
    w3 = 7
    ws = w1 + w2 + w3
    @text += "+#{'-' * (ws + 2)}+\n"
    rows.each do |row|
      @text += "|#{row[0].ljust(w1)}|#{row[1].ljust(w2)}|#{row[2].rjust(w3)}|\n"
    end
    @text += "+#{'-' * (ws + 2)}+\n"
  end

  def print()
    werase(@iwin)
    mvwaddstr(@iwin, 0, 0, @text)
    wrefresh(@win)
    wrefresh(@iwin)
  end
end

class TUIView
  def initialize(model)
    @model = model
    initscr
    curs_set 0
    noecho
    keypad stdscr, true
    scrollok stdscr, true

    @views = []
    @views << ClockView.new(model, y: 0, x: 0) \
    << DateView.new(model,  y: 0, x: 35) \
    << DashboardView.new(model, y:12, x:0) \
    << LogsView.new(model, y:0, x:58)
  end

  def print
    @views.each do |v|
      v.print
    end
  end
end

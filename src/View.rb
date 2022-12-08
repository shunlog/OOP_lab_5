#!/usr/bin/env ruby

require 'ffi-ncurses'
include FFI::NCurses

class ClockView
  attr_reader :text
  W = 20
  H = 7
  M = 2
  def initialize(model, time=0, y: 0, x: 0)
    @time = time
    model.add_observer(:time, self.method(:update))
    @win = newwin(H, W, y, x)
    box(@win, 0, 0)
    @iwin = derwin(@win, H-2*M, W-2*M, M, M)
    scrollok @iwin, true
  end

  def update(time)
    @text = "Minute #{time}"
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
  W = 18
  H = 7
  M = 2
  def initialize(model, date=1, y: 0, x: 0)
    update(date)
    model.add_observer(:date, self.method(:update))

    @win = newwin(H, W, y, x)
    box(@win, 0, 0)
    @iwin = derwin(@win, H-2*M, W-2*M, M, M)
    scrollok @iwin, true
  end

  def update(date)
    @text = "Day #{date}"
  end

  def print()
    werase(@iwin)
    mvwaddstr(@iwin, 0, 0, @text)
    wrefresh(@win)
    wrefresh(@iwin)
  end
end


class DashboardView
  attr_reader :text, :model

  W = 60
  H = 30
  M = 2
  def initialize(model, y: 0, x: 0)
    model.add_observer(:dashboard, self.method(:update))
    @model = model

    @win = newwin(H, W, y, x)
    box(@win, 0, 0)
    @iwin = derwin(@win, H-2*M, W-2*M, M, M)
    scrollok @iwin, true
  end

  def update()
    @text = ""

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
    # raw
    noecho
    keypad stdscr, true
    scrollok stdscr, true

    @clock_view = ClockView.new(model, y: 0, x: 0)
    @date_view = DateView.new(model,  y: 0, x: 20)
    @dashboard_view = DashboardView.new(model, y:8, x:0)
  end

  def print
    @clock_view.print
    @date_view.print
    @dashboard_view.print
  end
end

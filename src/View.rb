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
    @date_view = DateView.new(model,  y: 10, x: 0)
  end

  def print
    @clock_view.print
    @date_view.print
  end
end

#!/usr/bin/env ruby

require 'ffi-ncurses'
include FFI::NCurses

class ClockView
  attr_reader :text
  def initialize(model, time=0)
    @time = time
    model.add_observer(:time, self.method(:update))
  end

  def update(time)
    @text = "#{time}"
  end
end

class DateView
  attr_reader :text
  def initialize(model, date=1)
    update(date)
    model.add_observer(:date, self.method(:update))
  end

  def update(date)
    @text = "#{date}"
  end
end


class TUIView
  def initialize(model)
    @model = model

    initscr
    curs_set 0
    raw
    noecho
    keypad stdscr, true
    scrollok stdscr, true

    @win1 = newwin(7, 20, 4, 15)
    box(@win1, 0, 0)
    @win2 = newwin(7, 20, 20, 15)
    box(@win2, 0, 0)

    @iwin1 = derwin(@win1, 4, 8, 2, 2)
    @iwin2 = derwin(@win2, 4, 8, 2, 2)

    scrollok @iwin1, true
    scrollok @iwin2, true

    @clock_view = ClockView.new(model)
    @date_view = DateView.new(model)
  end

  def print
    werase(@iwin1)
    werase(@iwin2)
    mvwaddstr(@iwin1, 0, 0, @clock_view.text)
    mvwaddstr(@iwin2, 0, 0, @date_view.text)

    wrefresh(@win1)
    wrefresh(@win2)
    wrefresh(@iwin1)
    wrefresh(@iwin2)
  end
end

#!/usr/bin/env ruby

class ClockView
  attr_reader :text
  def initialize(model, time=0)
    @time = time
    model.add_observer(:time, self.method(:update))
  end

  def update(time)
    @text = "#{time}"
  end

  def print
    puts @text
  end
end

class TUIView
  def initialize(model)
    @clock_view = ClockView.new(model)
  end
  def print
    @clock_view.print
  end
end

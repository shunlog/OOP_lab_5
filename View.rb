#!/usr/bin/env ruby

class View
  def initialize(model, time)
    @time = time
    model.add_observer(:time, self.method(:update))
  end

  def update(time)
    pp "#{time}"
  end
end

#!/usr/bin/env ruby

class TUIController
  def initialize(model)
    @model = model
    @play = true
  end

  def KEY(ch)
    ch[0].ord
  end

  def handle_key(ch)
    if ch == KEY("q")
      exit
    elsif ch == KEY(" ")
      @play = !@play
    end

    if @play or ch == KEY("n")
      @model.step
    end
  end
end

#!/usr/bin/env ruby
# frozen_string_literal: true

class Agent
  attr_accessor :state

  def initialize(model)
    @model = model
  end

  def step; end
end

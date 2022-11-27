#!/usr/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'sciruby'
require 'json'
require_relative 'Order'
require_relative 'Customer'
require_relative 'Cook'
require_relative 'Waiter'

class Model
  attr_accessor :customers, :waiters, :cooks, :steps,
                :menu, :order_holder, :ledge, :served,
                :prng, :profit, :daily_metrics, :waiting_times,
                :logger

  MIN_POPULARITY = 10
  START_HOUR = 8
  END_HOUR = 20
  CLOSING_HOUR = 19
  START_TIME = Time.new(2022, 1, 1, START_HOUR, 0, 0)

  DailyMetrics = Struct.new(:profit, :served, :avg_rating, :avg_waiting_time, :popularity, :ratings)
  Menu = Struct.new(:burgers, :fries, :drinks)
  MenuItem = Struct.new(:name, :prep_time, :price, :profit_margin)

  Burgers = [MenuItem.new('Fat Burger', 10, 4.99, 0.2)] +
            [MenuItem.new('Little Johnny', 8, 3.99, 0.2)]
  Fries = [MenuItem.new('Soggy Fries', 5, 1.99, 0.3)] +
          [MenuItem.new('Greasy Fingers', 6, 2.99, 0.3)]
  Drinks = [MenuItem.new('Overpriced tea', 1, 1.99, 0.9)] +
           [MenuItem.new('Overpriced drink', 1, 1.99, 0.9)]

  def initialize(cooks_count: 5,
                 waiters_count: 1,
                 tables_count: 20,
                 initial_popularity: 10,
                 population: 500,
                 cook_salary: 80.0,
                 show_stats: false,
                 stats_frequency: 60,
                 logger_level: Logger::WARN)

    @tables_count = tables_count
    @initial_popularity = initial_popularity # number of customers daily
    @cook_salary = cook_salary
    @population = population
    @show_stats = show_stats
    @stats_frequency = stats_frequency

    @logger = Logger.new($stdout)
    @logger.level = logger_level
    logger.formatter = proc do |_severity, _datetime, _progname, msg|
      ">>> Day #{@day} -- #{time}: #{msg}\n"
    end

    @ratings = []
    @popularity = nil
    @menu = Menu.new(Burgers, Fries, Drinks)
    @daily_metrics = []
    @day = 1

    @waiters = []
    waiters_count.times do
      @waiters << Waiter.new(self)
    end
    @cooks = []
    cooks_count.times do
      @cooks << Cook.new(self)
    end
    @customers = []

    start_day
  end

  def agents
    @waiters | @cooks | @customers
  end

  def start_day
    @steps = 0
    @order_holder = []
    @ledge = []
    @waiting_times = []
    @profit = 0
    @served = 0
    @popularity = if @popularity
                    new_day_new_popularity
                  else
                    @initial_popularity
                  end
    # @ratings = []
    @cooks.each(&:start_day)
    @waiters.each(&:start_day)
    @logger.info { "Starting day #{@day}" }
  end

  def pareto(x, xm, a)
    if x >= xm
      (a * xm**a) / (x**(a + 1))
    else
      0
    end
  end

  def population_ratio(rating)
    xm = 1
    a = 1.16
    rating_filter = pareto(5.0 + xm - rating, xm, a) / a
    count_filter = rating_filter * [(@ratings.size.to_f / @population), 1.0].min
    [count_filter, 1].min
  end

  def new_day_new_popularity
    pop = @population.to_f * population_ratio(avg_rating)
    @logger.info do
      "New popularity of the restaurant is #{pop},\n\
 given that the rating is #{avg_rating} and there are #{@population} people."
    end
    pop
  end

  def wrap_up
    print_stats
    @customers.each(&:wrap_up)
    @customers = []
    pay_cooks
    store_daily_metrics
    @day += 1
    start_day
  end

  def customer_appears
    unless @customers.size < @tables_count
      @popularity -= 1
      return
    end
    c = Customer.new(self)
    @customers << c
  end

  def closing_min
    (CLOSING_HOUR - START_HOUR) * 60
  end

  def closing_time
    @steps > closing_min
  end

  def customers_appear
    return if closing_time

    mean = @popularity.to_f / work_minutes # mean nr of customers per minute
    n = Distribution::Poisson.rng(mean)
    n.times do
      customer_appears
    end
  end

  def start_closing
    @logger.info { "Starting closing. Customers can't enter anymore." }
  end

  def step
    @steps += 1
    print_stats if (@steps % @stats_frequency).zero?
    customers_appear
    agents.each(&:step)
    start_closing if @steps == closing_min
    wrap_up if (@steps % work_minutes).zero?
  end

  def avg_waiting_time
    return 0 if @waiting_times.size.zero?

    (@waiting_times.sum.to_f / @waiting_times.size).round
  end

  def avg_rating
    return 0 if @ratings.size.zero?

    (@ratings.sum.to_f / @ratings.size).round(1)
  end

  def pay_cooks
    @profit -= @cooks.size * @cook_salary
  end

  def store_daily_metrics
    @daily_metrics << DailyMetrics.new(profit, @served, avg_rating,
                                       avg_waiting_time, @popularity, @ratings.dup)
  end

  def run_a_day
    (work_hours * 60).times do
      step
    end
  end

  def work_hours
    END_HOUR - START_HOUR
  end

  def work_minutes
    work_hours * 60
  end

  def time
    @steps = 0 if @steps.nil?
    t = START_TIME
    t += @steps * 60
    t += (@day - 1) * 60 * 60 * 24
    t.strftime '%H:%M'
  end

  def rate(rating)
    @ratings << rating
  end

  def print_stats
    return unless @show_stats

    rows = [
      ['People', '', agents.size.to_s],
      ['Customers', '', @customers.size.to_s],
      ['', 'Choosing order', @customers.filter { |c| c.state == :choosing_order }.size.to_s],
      ['', 'Waiting waiter', @customers.filter { |c| c.state == :waiting_waiter }.size.to_s],
      ['', 'Waiting food', @customers.filter { |c| c.state == :waiting_food }.size.to_s],
      ['', 'Eating', @customers.filter { |c| c.state == :eating }.size.to_s],
      ['', 'Waiting check', @customers.filter { |c| c.state == :waiting_check }.size.to_s],

      ['Waiters', '', @waiters.size.to_s],
      ['', 'Waiting', @waiters.filter { |c| c.state == :waiting }.size.to_s],
      ['', 'Cleaning table', @waiters.filter { |c| c.state == :cleaning_table }.size.to_s],

      ['Cooks', '', @cooks.size.to_s],
      ['', 'Waiting', @cooks.filter { |c| c.state == :waiting }.size.to_s],
      ['', 'Cooking', @cooks.filter { |c| c.state == :cooking }.size.to_s],

      ['Tables', '', @tables_count.to_s],
      ['', 'Free', (@tables_count - @customers.size).to_s],

      ['Served', '', @served.to_s],

      ['Profit', '', @profit.round(2).to_s],
      ['Rating', '', avg_rating.to_s]
    ]
    w1 = 10
    w2 = 20
    w3 = 7
    ws = w1 + w2 + w3
    puts "+#{'-' * (ws + 2)}+"
    puts "|#{"Time: #{time}, Day: #{@day}".center(ws + 2)}|"
    puts "+#{'-' * (ws + 2)}+"
    rows.each do |row|
      puts "|#{row[0].ljust(w1)}|#{row[1].ljust(w2)}|#{row[2].rjust(w3)}|"
    end
    puts "+#{'-' * (ws + 2)}+"
  end

  def print_daily_metrics
    @daily_metrics.each do |m|
      print m.profit.round(2), "\t", m.served, "\t", m.avg_rating, "\t",
            m.avg_waiting_time, "\t", m.popularity, "\n"
    end
  end

  def daily_metrics_hash
    @daily_metrics.map(&:to_h)
  end

  def json_daily_metrics
    JSON.generate(daily_metrics_hash)
  end
end

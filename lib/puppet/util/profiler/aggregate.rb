require 'puppet/util/profiler'
require 'puppet/util/profiler/wall_clock'

class Puppet::Util::Profiler::Aggregate < Puppet::Util::Profiler::WallClock
  def initialize(logger, identifier)
    super(logger, identifier)
    @metrics_hash = Metric.new
  end

  def do_start(metric, description)
    super(metric, description)
  end

  def do_finish(context, metric, description)
    result = super(context, metric, description)
    update_metric(@metrics_hash, metric, result[:time])
    result
  end

  def update_metric(metrics_hash, metric, time)
    first, *rest = *metric
    m = metrics_hash[first]
    m.increment
    m.add_time(time)
    if rest.count > 0
      update_metric(m, rest, time)
    end
  end

  def values
    @metrics_hash
  end

  class Metric < Hash
    def initialize
      super
      @count = 0
      @time = 0
    end
    attr_reader :count, :time

    def [](key)
      if !has_key?(key)
        self[key] = Metric.new
      end
      super(key)
    end

    def increment
      @count += 1
    end

    def add_time(time)
      @time += time
    end
  end

  class Timer
    def initialize
      @start = Time.now
    end

    def stop
      Time.now - @start
    end
  end
end
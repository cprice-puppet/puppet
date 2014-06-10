class Puppet::Util::Profiler::Logging
  def initialize(logger, identifier)
    @logger = logger
    @identifier = identifier
    @sequence = Sequence.new
  end

  def start(metric, description)
    @sequence.next
    @sequence.down
    do_start(metric, description)
  end

  def finish(context, metric, description)
    profile_explanation = do_finish(context, metric, description)[:msg]
    @sequence.up
    @logger.call("PROFILE [#{@identifier}] #{@sequence} #{description}: #{profile_explanation}")
  end

  class Sequence
    INITIAL = 0
    SEPARATOR = '.'

    def initialize
      @elements = [INITIAL]
    end

    def next
      @elements[-1] += 1
    end

    def down
      @elements << INITIAL
    end

    def up
      @elements.pop
    end

    def to_s
      @elements.join(SEPARATOR)
    end
  end
end

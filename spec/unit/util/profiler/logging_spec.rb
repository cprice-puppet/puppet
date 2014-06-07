require 'spec_helper'
require 'puppet/util/profiler'

describe Puppet::Util::Profiler::Logging do
  let(:logger) { SimpleLog.new }
  let(:identifier) { "Profiling ID" }
  let(:profiler) { TestLoggingProfiler.new(logger, identifier) }

  before :each do
    Puppet::Util::Profiler.add_profiler(profiler)
  end

  after :each do
    Puppet::Util::Profiler.remove_profiler(profiler)
  end

  it "logs the explanation of the profile results" do
    Puppet::Util::Profiler.profile("Testing") { }

    logger.messages.first.should =~ /the explanation/
  end

  it "describes the profiled segment" do
    Puppet::Util::Profiler.profile("Tested measurement") { }

    logger.messages.first.should =~ /PROFILE \[#{identifier}\] \d Tested measurement/
  end

  it "indicates the order in which segments are profiled" do
    Puppet::Util::Profiler.profile("Measurement") { }
    Puppet::Util::Profiler.profile("Another measurement") { }

    logger.messages[0].should =~ /1 Measurement/
    logger.messages[1].should =~ /2 Another measurement/
  end

  it "indicates the nesting of profiled segments" do
    Puppet::Util::Profiler.profile("Measurement") { Puppet::Util::Profiler.profile("Nested measurement") { } }
    Puppet::Util::Profiler.profile("Another measurement") { Puppet::Util::Profiler.profile("Another nested measurement") { } }

    logger.messages[0].should =~ /1.1 Nested measurement/
    logger.messages[1].should =~ /1 Measurement/
    logger.messages[2].should =~ /2.1 Another nested measurement/
    logger.messages[3].should =~ /2 Another measurement/
  end

  class TestLoggingProfiler < Puppet::Util::Profiler::Logging
    def do_start
      "the start"
    end

    def do_finish(context)
      "the explanation of #{context}"
    end
  end

  class SimpleLog
    attr_reader :messages

    def initialize
      @messages = []
    end

    def call(msg)
      @messages << msg
    end
  end
end


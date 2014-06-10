require 'spec_helper'
require 'puppet/util/profiler'
require 'puppet/util/profiler/aggregate'

describe Puppet::Util::Profiler::Aggregate do
  let(:logger) { Puppet::Util::Profiler::Aggregate::SimpleLog.new }

  it "tracks the aggregate counts and time for the hierarchy of metrics" do
    profiler = Puppet::Util::Profiler::Aggregate.new(logger, nil)

    Puppet::Util::Profiler.add_profiler(profiler)

    begin
      Puppet::Util::Profiler.profile(["function", "hiera_lookup", "production"], "Looking up hiera data in production environment") {}
      Puppet::Util::Profiler.profile(["function", "hiera_lookup", "test"], "Looking up hiera data in test environment") {}
      Puppet::Util::Profiler.profile(["compiler", "lookup"], "looking up stuff for compilation") {}
      Puppet::Util::Profiler.profile(["compiler", "compiling"], "COMPILING ALL OF THE THINGS!") {}

      profiler.values["function"].count.should == 2
      profiler.values["function"].time.should be > 0
      profiler.values["function"]["hiera_lookup"].count.should == 2
      profiler.values["function"]["hiera_lookup"]["production"].count.should == 1
      profiler.values["function"]["hiera_lookup"]["test"].count.should == 1
      profiler.values["function"].time.should be >= profiler.values["function"]["hiera_lookup"].time

      profiler.values["compiler"].count.should == 2
      profiler.values["compiler"].time.should be > 0
      profiler.values["compiler"]["lookup"].count.should == 1
      profiler.values["compiler"]["compiling"].count.should == 1
      profiler.values["compiler"].time.should be >= profiler.values["compiler"]["lookup"].time

      profiler.shutdown

      logger.output.should =~ /function: .*\(2 calls\)\nfunction -> hiera_lookup:.*\(2 calls\)/
      logger.output.should =~ /compiler: .*\(2 calls\)\ncompiler -> compiling:.*\(1 calls\)/
    ensure
      Puppet::Util::Profiler.remove_profiler(profiler)
    end
  end

  class SimpleLog
    attr_reader :output

    def initialize
      @output = ""
    end

    def call(msg)
      @output << msg << "\n"
    end
  end
end

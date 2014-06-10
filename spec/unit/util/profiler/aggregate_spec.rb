require 'spec_helper'
require 'puppet/util/profiler'
require 'puppet/util/profiler/aggregate'

describe Puppet::Util::Profiler::Aggregate do

  it "tracks the aggregate counts and time for the hierarchy of metrics" do
    profiler = Puppet::Util::Profiler::Aggregate.new(Proc.new {}, nil)

    Puppet::Util::Profiler.add_profiler(profiler)

    begin
      Puppet::Util::Profiler.profile(["foo"], "doing foo") { }
      Puppet::Util::Profiler.profile(["bar"], "doing bar") { }
      Puppet::Util::Profiler.profile(["foo", "booyah"], "nested metric") do
        Puppet::Util::Profiler.profile(["foo", "booyah", "shazaam"], "super nested!") {}
      end

      profiler.values["foo"].count.should == 3
      profiler.values["foo"].time.should be > 0
      profiler.values["bar"].count.should == 1
      profiler.values["foo"]["booyah"].count.should == 2
      profiler.values["foo"]["booyah"].time.should be > 0
      profiler.values["foo"]["booyah"]["shazaam"].count.should == 1
      profiler.values["foo"]["booyah"]["shazaam"].time.should be > 0
    ensure
      Puppet::Util::Profiler.remove_profiler(profiler)
    end
  end
end

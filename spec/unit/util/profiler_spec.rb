require 'spec_helper'
require 'puppet/util/profiler'

describe Puppet::Util::Profiler do
  let(:profiler) { TestProfiler.new() }

  before :each do
    subject.add_profiler(profiler)
  end

  after :each do
    subject.remove_profiler(profiler)
  end

  it "returns the value of the profiled segment" do
    retval = subject.profile(["foo", "bar"], "Testing") { "the return value" }

    retval.should == "the return value"
  end

  it "propogates any errors raised in the profiled segment" do
    expect do
      subject.profile(["foo", "bar"], "Testing") { raise "a problem" }
    end.to raise_error("a problem")
  end

  it "makes the metric id, description and the context available to the `start` and `finish` methods" do
    subject.profile(["foo", "bar"], "Testing") { }

    profiler.context[:metric].should == ["foo", "bar"]
    profiler.context[:description].should == "Testing"
    profiler.metric.should == ["foo", "bar"]
    profiler.description.should == "Testing"
  end

  it "calls finish even when an error is raised" do
    begin
      subject.profile(["foo", "bar"], "Testing") { raise "a problem" }
    rescue
      profiler.context[:description].should == "Testing"
    end
  end

  it "supports multiple profilers" do
    profiler2 = TestProfiler.new
    subject.add_profiler(profiler2)
    subject.profile(["foo", "bar"], "Testing") {}

    profiler.context[:description].should == "Testing"
    profiler2.context[:description].should == "Testing"
  end

  class TestProfiler
    attr_accessor :context, :metric, :description

    def start(metric, description)
      {:metric => metric,
       :description => description}
    end

    def finish(context, metric, description)
      @context = context
      @metric = metric
      @description = description
    end
  end
end


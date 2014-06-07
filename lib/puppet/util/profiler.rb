require 'benchmark'

# A simple profiling callback system.
#
# @api public
module Puppet::Util::Profiler
  require 'puppet/util/profiler/wall_clock'
  require 'puppet/util/profiler/object_counts'

  @profilers = []

  # Reset the profiling system to the original state
  #
  # @api private
  def self.clear
    @profilers = []
  end

  # @param profiler [#profile] A profiler for the current thread
  # @api private
  def self.add_profiler(profiler)
    @profilers << profiler
    profiler
  end

  # @param profiler [#profile] A profiler to remove from the current thread
  # @api private
  def self.remove_profiler(profiler)
    @profilers.delete(profiler)
  end

  # Profile a block of code and log the time it took to execute.
  #
  # This outputs logs entries to the Puppet masters logging destination
  # providing the time it took, a message describing the profiled code
  # and a leaf location marking where the profile method was called
  # in the profiled hierachy.
  #
  # @param message [String] A description of the profiled event
  # @param block [Block] The segment of code to profile
  # @api public
  def self.profile(message)
    retval = nil
    contexts = {}
    @profilers.each do |profiler|
      contexts[profiler] = profiler.start(message)
    end

    begin
      retval = yield
    ensure
      @profilers.each do |profiler|
        profiler.finish(contexts[profiler], message)
      end
    end

    retval
  end
end

require 'puppet/pops/binder/producers'

class Foo
  def initialize(a, b)
    @a = a
    @b = b
  end

  def to_s
    "plain old foo: #{@a}, #{@b}"
  end
end

class FooBar < Foo
  def initialize(a, b)
    @a = a
    @b = b
  end

  def to_s
    "fooBAR: #{@a}, #{@b}"
  end
end

class FooBaz < Foo
  def initialize(a, b)
    @a = a
    @b = b
  end

  def to_s
    "fooBAZ: #{@a}, #{@b}"
  end
end

# TODO: I assume I'd need to implement one of these for the FooBaz
# class as well?
class FooBarProducer < Puppet::Pops::Binder::Producers::Producer
  def produce(scope, a, b)
    FooBar.new(a, b)
  end
end
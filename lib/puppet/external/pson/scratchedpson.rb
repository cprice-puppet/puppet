m = {:nested => {:foo => [:bar, :baz]}}

def wrap_it_up_b(x)
  if (x.is_a?(Hash))
    return MapWrapper.new(x)
  elsif (x.is_a?(Array))
    return ArrayWrapper.new(x)
  else
    return x
  end
end

class ArrayWrapper
  def initialize(a)
    @a = a
  end

  def [](index)
    v = @a[index]
    wrap_it_up_b(v)
  end

  def map
    @a.map do |v|
      yield wrap_it_up_b(v)
    end
  end
end

class MapWrapper
  def initialize(m)
    @m = m
  end

  def [](k)
    return nil unless @m.has_key?(k)
    v = @m[k]
    wrap_it_up_b(v)
  end
end

mw = MapWrapper.new(m)
puts mw[:nested]
puts mw[:nested][:foo]
mw[:nested][:foo].map do |x|
  puts "mapped over #{x}"
end

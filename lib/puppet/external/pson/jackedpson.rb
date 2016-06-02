# require 'puppet/external/pson/common'
# require 'puppet/external/pson/version'
#require 'puppet/external/pson/pure'

require 'java'

java_import org.slf4j.LoggerFactory
java_import com.puppetlabs.puppetserver.JRubyPuppet
java_import java.util.Map
java_import java.util.List
java_import java.io.ByteArrayInputStream
java_import java.io.ByteArrayOutputStream
java_import "puppetlabs.jackson.unencoded.JackedSonMapper"
java_import "puppetlabs.jackson.pson.PsonEncodingInputStreamWrapper"
java_import "puppetlabs.jackson.pson.PsonDecodingInputStreamWrapper"
java_import "puppetlabs.jackson.pson.PsonDecodingInputStreamWrapper$PsonDecodedInputStream"

# PsonDecodingInputStreamWrapper::PsonDecodedInputStream.class_eval do
#   def to_s
#     # TODO: examine memory usage, try to avoid copying
#     self.to_io.read
#   end
#
#   def intern
#     to_s.intern
#   end
#
#   def ==(other)
#     to_s == other
#   end
# end

class PSON
  @@mapper = JackedSonMapper.new(PsonEncodingInputStreamWrapper.new,
                                 PsonDecodingInputStreamWrapper.new)

  def self.mapper
    @@mapper
  end

  def self.parse(s)
    # TODO: probably making lots of copies of things here, need to see if there's
    # a way to avoid that.
    result = mapper.read_value(ByteArrayInputStream.new(s.to_java_bytes))
    PSON::Parser.wrap_it_up_b(result)
  end

  class Parser

    def self.wrap_it_up_b(v)
      if v.is_a?(Map)
        convert_map(v)
      elsif v.is_a?(List)
        convert_list(v)
      elsif v.is_a?(PsonDecodingInputStreamWrapper::PsonDecodedInputStream)
        convert_pson_input_stream(v)
      elsif v.is_a?(Fixnum)
        v
      elsif v.is_a?(Float)
        v
      elsif v.is_a?(NilClass)
        nil
      elsif v.is_a?(FalseClass)
        false
      elsif v.is_a?(TrueClass)
        true
      else
        raise "Unsupported type: #{v.class}"
      end
    end

    def self.convert_map(m)
      rv = {}
      m.each do |k,v|
        rv[k] = wrap_it_up_b(v)
      end
      rv
    end

    def self.convert_list(a)
      rv = []
      a.each do |v|
        rv.push(wrap_it_up_b(v))
      end
      rv
    end

    def self.convert_pson_input_stream(is)
      # TODO: see if there is a way to make this more memory efficient
      is.to_io.read
    end
  end




  # def self.wrap_it_up_b(x)
  #   puts "WRAPPING X: #{x} (#{x.class})"
  #   if x.is_a?(Map)
  #     puts "ITSA MAP!"
  #     return MapWrapper.new(x)
  #   elsif (x.is_a?(List))
  #     puts "ITSA ARRAY!"
  #     return ListWrapper.new(x)
  #   elsif (x.is_a?(PsonDecodingInputStreamWrapper::PsonDecodedInputStream))
  #     puts "ITSA FUNKYSTRANG!"
  #     # TODO: examine memory usage, try to avoid copying
  #     return x.to_io.read
  #   else
  #     puts "IT AINT SHIT!"
  #     return x
  #   end
  # end
  #
  # class ListWrapper
  #   def initialize(a)
  #     @a = a
  #   end
  #
  #   def map
  #     @a.map do |v|
  #       yield PSON.wrap_it_up_b(v)
  #     end
  #   end
  #
  #   def each
  #     @a.each do |v|
  #       yield PSON.wrap_it_up_b(v)
  #     end
  #   end
  #
  #   def [](index)
  #     v = @a[index]
  #     PSON.wrap_it_up_b(v)
  #   end
  # end
  #
  # class MapWrapper
  #   def initialize(m)
  #     @m = m
  #   end
  #
  #   def map
  #     @m.map do |k,v|
  #       yield [k, PSON.wrap_it_up_b(v)]
  #     end
  #   end
  #
  #   def each
  #     @m.each do |k,v|
  #       yield [k, PSON.wrap_it_up_b(v)]
  #     end
  #   end
  #
  #   def [](k)
  #     puts "LOOKING FOR KEY: #{k}"
  #     return nil unless @m.has_key?(k)
  #     puts "ORIG MAP HAS THAT KEY, WRAPPING IT UP, B"
  #     v = @m[k]
  #     PSON.wrap_it_up_b(v)
  #   end
  #
  #   def delete(k)
  #     @m.delete(k)
  #   end
  #
  #   def to_yaml( opts = {} )
  #     YAML::quick_emit( object_id, opts ) do |out|
  #       out.map( taguri, to_yaml_style ) do |map|
  #         each do |k, v|
  #           map.add( k, PSON.wrap_it_up_b(v) )
  #         end
  #       end
  #     end
  #   end
  # end

  class Generator
    def self.wrap_it_up_b(v)
      puts "GENERATOR WRAPPING UP: #{v} (#{v.class})"
      if v.is_a?(Hash)
        convert_hash(v)
      elsif v.is_a?(Array)
        convert_list(v)
      elsif v.is_a?(String)
        v
      elsif v.is_a?(Symbol)
        v.to_s
      elsif v.is_a?(Fixnum)
        v
      elsif v.is_a?(Float)
        v
      elsif v.is_a?(NilClass)
        nil
      elsif v.is_a?(FalseClass)
        false
      elsif v.is_a?(TrueClass)
        true
      elsif v.respond_to?(:to_data_hash)
        wrap_it_up_b(v.to_data_hash)
      else
        raise "Unsupported type: #{v.class}"
      end
    end

    def self.convert_hash(m)
      rv = {}
      m.each do |k,v|
        rv[k] = wrap_it_up_b(v)
      end
      rv
    end

    def self.convert_list(a)
      rv = []
      a.each do |v|
        rv.push(wrap_it_up_b(v))
      end
      rv
    end
  end

end

class Array
  def to_pson
    wrapped = PSON::Generator.wrap_it_up_b(self)


    puts "ABOUT TO CONVERT ARRAY TO PSON: #{wrapped} (#{wrapped.class})"
    out = ByteArrayOutputStream.new
    PSON.mapper.write_value(out, wrapped)
    # TODO: this is definitely making an unnecessary copy
    ByteArrayInputStream.new(out.to_byte_array).to_io.read
  end
end

class Hash
  def to_pson
    puts "ABOUT TO CONVERT HASH TO PSON: #{self} (#{self.class})"
    if self.has_key?("environment")
      puts "\tENVIRONMENT KEY: #{self["environment"]} (#{self["environment"].class})"
    end
    out = ByteArrayOutputStream.new
    PSON.mapper.write_value(out, PSON::Generator.wrap_it_up_b(self))
    # TODO: this is definitely making an unnecessary copy
    ByteArrayInputStream.new(out.to_byte_array).to_io.read
  end
end





require 'yaml'

module Puppet::Util::Yaml
  if defined?(::Psych::SyntaxError)
    YamlLoadExceptions = [::StandardError, ::Psych::SyntaxError]
  else
    YamlLoadExceptions = [::StandardError]
  end

  class YamlLoadError < Puppet::Error; end

  def self.load_file(filename, default_value = false)
    puts "LOADING YAML FILE: #{filename} (#{filename.class})"
    yaml = YAML.load_file(filename)
    yaml || default_value
  rescue *YamlLoadExceptions => detail
    puts "YAML LOAD ERROR; DETAIL: #{detail} (#{detail.class})"
    puts "                 DETAIL message: #{detail.message} (#{detail.message.class})"
    raise YamlLoadError.new(detail.message, detail)
  end

  def self.dump(structure, filename)
    puts "!!!!!!!!!!!!! DUMPING YAML FILE: #{filename}, structure: #{structure} (#{structure.class})"
    Puppet::Util.replace_file(filename, 0660) do |fh|
      YAML.dump(structure, fh)
    end
  end
end

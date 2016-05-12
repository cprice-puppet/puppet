#!/usr/bin/env ruby

require 'hocon/config_factory'
require 'hocon/config_resolve_options'

class HoconLoader
  def self.parse(defaults_file, user_file)
    user_config = Hocon::ConfigFactory.parse_file(user_file)
    default_config = Hocon::ConfigFactory.parse_file(defaults_file)

    Hocon::ConfigFactory.
        load_from_config(user_config.with_fallback(default_config),
                         Hocon::ConfigResolveOptions.defaults).root.unwrapped
  end
end

describe "hocon merge with interpolation" do
  it "should work" do
    expect(HoconLoader.parse("./spec/scratch/config_files/default.conf",
                             "./spec/scratch/config_files/user.conf")).
        to eq({"vardir" => "./my-vardir",
               "reportdir" => "./my-vardir/reports"})
  end
end
#!/usr/bin/env ruby

require 'hocon/config_factory'
require 'hocon/config_resolve_options'

class HoconLoader
  def self.parse(defaults_file, user_file, run_mode)

    default_config = Hocon::ConfigFactory.parse_file(defaults_file)

    # compute dynamic values (certname, confdir, vardir, codedir)
    # facter fqdn -> default_config[certname]
    # if (root) -> confdir, vardir, codedir -> default_config
    # if (runmode) -> default_config (? do we need this or can we handle it in defaults)?

    user_config = Hocon::ConfigFactory.parse_file(user_file)

    resolved_config = Hocon::ConfigFactory.
        load_from_config(user_config.with_fallback(default_config),
                         Hocon::ConfigResolveOptions.defaults).root.unwrapped



    # filter out any nested maps to give us just the resolved "main" settings,
    # since we know that Puppet only supports scalar settings values, and our
    # goal is to overlay the run-mode settings onto the main settings.
    main_config = resolved_config.reject do |k, v|
      v.instance_of?(Hash)
    end

    # Now grab the relevant settings for the specified run mode
    run_mode_config = resolved_config[run_mode]

    # finally, merge the run_mode settings onto the "main" settings.
    main_config.merge(run_mode_config)

    # special case logic here for certname, and certname-derived settings
  end
end

describe "hocon merge with interpolation" do
  defaults_file = "./spec/scratch/config_files/default.conf"
  user_file = "./spec/scratch/config_files/user.conf"

  it "should load master runmode settings" do
    expect(HoconLoader.parse(defaults_file, user_file, "master")).
        to eq({"vardir" => "./my-vardir",
               "reportdir" => "./my-vardir/reports"})
  end

  it "should load agent runmode settings" do
    expect(HoconLoader.parse(defaults_file, user_file, "agent")).
        to eq({"vardir" => "./my-vardir",
               "reportdir" => "./my-vardir/agent-reports"})
  end
end
# Windows Service Control Manager (SCM) provider

require 'win32/service' if Puppet.features.microsoft_windows?

Puppet::Type.type(:service).provide :windows do

  desc "Support for Windows Service Control Manager (SCM).

  Services are controlled according to win32-service gem.

  * All SCM operations (start/stop/enable/disable/query) are supported.

  * Control of service groups (dependencies) is not yet supported."

  defaultfor :operatingsystem => :windows
  confine :operatingsystem => :windows

  has_feature :refreshable

  def enable
    w32ss = Win32::Service.configure( 'service_name' => @resource[:name], 'start_type' => Win32::Service::SERVICE_AUTO_START )
    raise Puppet::Error.new("Win32 service enable of #{@resource[:name]} failed" ) if( w32ss.nil? )
  rescue Win32::Service::Error => detail
    raise Puppet::Error.new("Cannot enable #{@resource[:name]}, error was: #{detail}" )
  end

  def disable
    w32ss = Win32::Service.configure( 'service_name' => @resource[:name], 'start_type' => Win32::Service::SERVICE_DISABLED )
    raise Puppet::Error.new("Win32 service disable of #{@resource[:name]} failed" ) if( w32ss.nil? )
  rescue Win32::Service::Error => detail
    raise Puppet::Error.new("Cannot disable #{@resource[:name]}, error was: #{detail}" )
  end

  def manual_start
    w32ss = Win32::Service.configure( 'service_name' => @resource[:name], 'start_type' => Win32::Service::SERVICE_DEMAND_START )
    raise Puppet::Error.new("Win32 service manual enable of #{@resource[:name]} failed" ) if( w32ss.nil? )
  rescue Win32::Service::Error => detail
    raise Puppet::Error.new("Cannot enable #{@resource[:name]} for manual start, error was: #{detail}" )
  end

  def enabled?
    w32ss = Win32::Service.config_info( @resource[:name] )
    raise Puppet::Error.new("Win32 service query of #{@resource[:name]} failed" ) unless( !w32ss.nil? && w32ss.instance_of?( Struct::ServiceConfigInfo ) )
    debug("Service #{@resource[:name]} start type is #{w32ss.start_type}")
    case w32ss.start_type
      when Win32::Service.get_start_type(Win32::Service::SERVICE_AUTO_START),
           Win32::Service.get_start_type(Win32::Service::SERVICE_BOOT_START),
           Win32::Service.get_start_type(Win32::Service::SERVICE_SYSTEM_START)
        true
      when Win32::Service.get_start_type(Win32::Service::SERVICE_DEMAND_START)
        :manual
      when Win32::Service.get_start_type(Win32::Service::SERVICE_DISABLED)
        false
      else
        raise Puppet::Error.new("Unknown start type: #{w32ss.start_type}")
    end
  rescue Win32::Service::Error => detail
    raise Puppet::Error.new("Cannot get start type for #{@resource[:name]}, error was: #{detail}" )
  end

  def start
    Win32::Service.start( @resource[:name] )
  rescue Win32::Service::Error => detail
    raise Puppet::Error.new("Cannot start #{@resource[:name]}, error was: #{detail}" )
  end

  def stop
    Win32::Service.stop( @resource[:name] )
  rescue Win32::Service::Error => detail
    raise Puppet::Error.new("Cannot start #{@resource[:name]}, error was: #{detail}" )
  end

  def restart
    self.stop
    self.start
  end

  def status
    w32ss = Win32::Service.status( @resource[:name] )
    raise Puppet::Error.new("Win32 service query of #{@resource[:name]} failed" ) unless( !w32ss.nil? && w32ss.instance_of?( Struct::ServiceStatus ) )
    state = case w32ss.current_state
      when "stopped", "pause pending", "stop pending", "paused" then :stopped
      when "running", "continue pending", "start pending"       then :running
      else
        raise Puppet::Error.new("Unknown service state '#{w32ss.current_state}' for service '#{@resource[:name]}'")
    end
    debug("Service #{@resource[:name]} is #{w32ss.current_state}")
    return state
  rescue Win32::Service::Error => detail
    raise Puppet::Error.new("Cannot get status of #{@resource[:name]}, error was: #{detail}" )
  end

  # returns all providers for all existing services and startup state
  def self.instances
    Win32::Service.services.collect { |s| new(:name => s.service_name) }
  end
end

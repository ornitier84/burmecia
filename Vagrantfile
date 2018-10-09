# -*- mode: ruby -*-
# vi: set ft=ruby :

# Clone the ARGV array for later use, rejecting any hyphened arguments
$vagrant_args = ARGV.clone
$vagrant_args.delete_if { |arg| arg.include?('--') }
# Load custom modules
require_relative 'lib/cli'
require_relative 'lib/environment'
require_relative 'lib/config'
require_relative 'lib/settings'
if $debug
  begin
    $logger.warn('Debugging enabled')
    require 'pry'
    require 'pry-rescue'
  rescue exception => e
    $logger.error($errors.debug.nopry)
  end
end
# Load built-in libraries
require 'date'
require 'yaml'

def main
  #
  # Specify minimum Vagrant/Vagrant API version
  #
  Vagrant.require_version "#{$vagrant.require_version}"
  # Instantiate the vagrant cli node class
  node = VenvCLI::Node.new
  # Instantiate the vagrant environments context class
  context = VenvEnvironment::Context.new
  # Get environment context (if applicable)
  environment_context = context.get
  # Read any environment-specific options
  context.join(environment_context)
  # Generate the node set
  node_set = context.activate(environment_context)
  # Instantiate the vagrant cli group class
  group = VenvCLI::Group.new
  # Boot up node groups if applicable
  group.up(node_set)
  # Treat managed/bare metal nodes
  node_set_managed = $managed ? context.activate(environment_context, managed: true) : []
  if $managed_node_args
    if $managed_node_args.length > 0
      node_set_managed = node_set_managed.select { |k, v| $managed_node_args.include?(k['name']) }
    end
  end
  # Instantiate the vagrant environments groups class
  groups = VenvEnvironment::Groups.new
  # Generate the group set
  @group_set = groups.generate(node_set)
  # Instantiate the vagrant machine ssh settings class
  ssh_settings = VenvSettings::SSH.new
  # Instantiate the vagrant machine config settings class
  machine_settings = VenvSettings::Config.new
  # Warn us if we're calling provisionment and ansible is in 'controller' mode
  if [ $ansible.mode == 'controller', $vagrant_args.first == 'provision', $vagrant_args.last != $ansible.surrogate].all?
    $logger.warn($warnings.provisioners.ansible.controller.skipping % {machine: '{{ node_name }}', surrogate: $ansible.surrogate })
  end
  # Process Virtual Machines
  Vagrant.configure($vagrant.api_version) do |config|
    node_set.each do |node_object|
        # Configure ssh settings
        ssh_settings.evaluate(node_object, config)
        # Read node autostart option
        autostart_setting = [node_object.key?('autostart'),!node_object['autostart'].nil?].all? ? node_object['autostart'] : $vagrant.defaults.autostart
        # Define node
        config.vm.define node_object['name'], autostart: autostart_setting do |machine|
          # Evaluate machine.vm settings
          machine_settings.evaluate(node_object, machine)
          if ["halt", "destroy"].any? { |arg| ARGV.include? arg }
            node.down(node_object, machine) 
          elsif ["up", "provision", "reload"].any? { |arg| ARGV.include? arg }
            node.up(node_object, node_set, config, machine)
          end
        end
    end
  end
  # Process managed/bare metal nodes
  if $ARGV.include?('--managed')
    # Print the status header if we're querying node status
    if ARGV.include? "status"
      $logger.info($info.managed.status.header)
    end
    node_set_managed.each do |node_object|
        # Read node autostart option
        autostart_setting = [node_object.key?('autostart'),!node_object['autostart'].nil?].all? ? node_object['autostart'] : false
        # Define boot timeout
        boot_timeout = node_object['boot_timeout'] if node_object.key?('boot_timeout')
        # Node actions
        if ["halt", "destroy"].any? { |arg| ARGV.include? arg }
          node.down(node_object)
        elsif ARGV.include? "status"
          node.stat(node_object, node_set_managed)
        elsif ["up", "provision", "reload"].any? { |arg| ARGV.include? arg }
          node.up(node_object, node_set)
        end
    end 
  end

  at_exit {
      if $nodes_were_skipped
        $logger.warn($warnings.definition.skipped) 
      end
      if node_set.empty? and !(["environment", "inventory"].any? { |arg| ARGV.include? arg })
        $logger.warn($warnings.context.nodes.empty)
      end   
        if [ "destroy", "halt", "port", "provision", "reload", "status", "up" ].include?(ARGV[0])
          endtime = Time.now
          t = endtime - DateTime.parse($starttime).to_time
          $logger.info($info.time.elapsed % t)  
        end
  }
end

# Only invoke the main function if none of our custom commands have been called
if ![ "environment","inventory","edit", "group", "node", "rake", "option" ].include?(ARGV[0])
  if $debug and $pry_debugger_available
    Pry::rescue{ main }
  else
    begin
      main
    rescue Exception => e
      $logger.error($errors.unhandled % [e, e.backtrace.first.to_s.bold])
      abort
    end
  end
end

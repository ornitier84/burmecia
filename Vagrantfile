# -*- mode: ruby -*-
# vi: set ft=ruby :
# Clone the ARGV array for later use, rejecting any hyphenated arguments
$vagrant_args = ARGV.clone
$vagrant_args.delete_if { |arg| arg.include?('--') }
# Load built-in libraries
require 'date'
require 'yaml'
# Load custom libraries
require 'config/settings'
require 'environment/main'
require 'machine/controller'
require 'commands/lib/environment.commands'
if $debug
  begin
    require 'pry'
    require 'pry-rescue'
  rescue exception => e
    $logger.error($errors.debug.nopry)
    $debug = false
  end
end

def main

  # Specify minimum Vagrant/Vagrant API version
  Vagrant.require_version "#{$vagrant.require_version}"
  # Instantiate the vagrant cli node class
  _machine = VenvMachine::Controller.new
  # Instantiate the vagrant environments context class
  context = VenvEnvironment::Main.new
  # Get environment context (if applicable)
  environment_context = context.get
  # Activate default environment context if none is detected
  if environment_context.empty?
    env = VenvCommandsEnvironment::Commands.new
    environment_context = $environment.defaults.context
    $logger.warn($warnings.context.environment.activate_default % environment_context)
    env.activate(environment_context)
  end
  # Read any environment-specific options
  context.join(environment_context)
  # Warn us if we're calling provisionment and ansible is in 'controller' mode
  if [
    $ansible.mode == 'controller',
    $vagrant_args.first == 'provision',
    $vagrant_args.last != $ansible.surrogate].all?
    $logger.warn($warnings.provisioners.ansible.controller.skipping % {
      machine: '{{ node_name }}', surrogate: $ansible.surrogate 
    }
    )
  end
  # Generate the node set
  node_set = context.generate_nodeset(environment_context)
  # Instantiate the vagrant cli group class
  group = VenvMachine::Group.new
  # Boot up node groups if applicable
  group.up(node_set)
  # Instantiate the vagrant environments groups class
  # groups = VenvEnvironment::Groups.new
  # Generate the group set
  @group_set = context.generate_groupset(node_set)
  # Instantiate the vagrant machine ssh settings class
  ssh_settings = VenvSettings::SSH.new
  # Instantiate the vagrant machine config settings class
  machine_settings = VenvSettings::Config.new
  # Process Virtual Machines
  Vagrant.configure($vagrant.api_version) do |config|
    node_set.each do |node_object|
        # Configure ssh settings
        ssh_settings.evaluate(node_object, config)
        # Read node autostart option
        autostart_setting =
          if node_object.dig('autostart')
            node_object['autostart']
          else
            $vagrant.defaults.autostart
          end        
          # Define node
          config.vm.define node_object['name'], autostart: autostart_setting do |machine|
          # Evaluate machine.vm settings
          machine_settings.evaluate(node_object, machine)
          if ["halt", "destroy"].any? { |arg| ARGV.include? arg }
            _machine.down(node_object, machine) 
          elsif ["up", "provision", "reload"].any? { |arg| ARGV.include? arg }
            _machine.up(node_object, node_set, config, machine)
          end
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
        if ["destroy", "halt", "port", "provision", "reload", "status", "up"].include?(ARGV[0])
          endtime = Time.now
          t = endtime - DateTime.parse($starttime).to_time
          $logger.info($info.time.elapsed % t)  
        end
  }
end
# Only invoke the main function if none of our custom commands have been called
unless $vagrant.commands.noexec.include?(ARGV[0])
  
  # Enforce per-environment dotfile path setting if so configured
  if $vagrant.separate_dotfile_paths

    is_set = [
      ENV['VAGRANT_DOTFILE_PATH'],
      ENV['VAGRANT_DOTFILE_PATH'] != '.vagrant/',
      ENV['VAGRANT_DOTFILE_PATH'].include?($environment.current_context)
    ].all?
    unless is_set
      $logger.error($errors.vagrant.no_env_dotfile % 
        {  env:$environment.defaults.context, args:ARGV.join(' ') }
        )
      abort
    end
  end

  if $debug and defined? Pry::rescue
    $logger.warn('Debugging enabled')
    Pry::rescue{ main }
  else
    begin
      main
    rescue Exception => err
      $logger.error($errors.unhandled % {
        errmessage: err, 
        firstline: err.backtrace.first.to_s,
        backtrace: "\tat #{err.backtrace.to_yaml}" }
      )
      abort
    end
  end
else
  $logger.warn($warnings.vagrant.noexec)
end

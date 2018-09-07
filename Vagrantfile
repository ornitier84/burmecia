# -*- mode: ruby -*-
# vi: set ft=ruby :

# Bail out if we don't need to load the Vagrantfile
exit if [ "environment","inventory","edit", "group", "node", "rake", "option" ].include?(ARGV[0])

# Load custom modules
require_relative 'lib/cli'
require_relative 'lib/environment'
require_relative 'lib/config'
if $debug
  begin
    require 'pry'
    require 'pry-rescue'
  rescue exception => e
    $logger.error($errors.debug.nopry)
  end
end
# Load built-in libraries
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
  # Are we targeting a single machine?
  target_machine = node_set.select { |k, v| k['name'] == ARGV[-1] }
  # Are we provisioning all machines?
  all_machines = true if ARGV[-1] == 'provision' and [target_machine.nil?, target_machine.empty?].any?
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
  # Instantiate the vagrant machine settings class
  settings = VenvMachine::Settings.new
  # Process Virtual Machines
  Vagrant.configure($vagrant.api_version) do |config|
    node_set.each do |node_object|
        # Configure ssh settings
        settings.eval_ssh(node_object, config)
        # Read node autostart option
        autostart_setting = [node_object.key?('autostart'),!node_object['autostart'].nil?].all? ? node_object['autostart'] : false
        # Define node
        config.vm.define node_object['name'], autostart: autostart_setting do |machine|
          # Set hostname
          machine.vm.hostname = node_object['name']
          # Specify vagrant box
          machine.vm.box = node_object['box']        
          if ["halt", "destroy"].any? { |arg| ARGV.include? arg }
            node.down(node_object, machine) 
          elsif ["up", "provision", "reload"].any? { |arg| ARGV.include? arg }
            node.up(node_object, node_set, config, machine, target_machine)
          end
        end
    end
  end
  # Process managed/bare metal nodes
  if $managed
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
  }
end

if $debug
  Pry.rescue do
    main  
  end
else
  begin
    main
  rescue Exception => e
    $logger.error($errors.unhandled % e.to_s.bold)
    exit
  end
end
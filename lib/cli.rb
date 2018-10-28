module VenvCLI

  class Node

    def initialize

      # Load libraries
      require 'common'
      require 'linked'
      require 'provision'
      require 'machine'
      require 'networking'
      # Instantiate the vagrant network class
      @network = VenvNetworking::Network.new
      # Instantiate the vagrant hardware class
      @hardware = VenvMachine::Hardware.new
      # Instantiate the vagrant syncedfolders class
      @syncedfolders = VenvMachine::SyncedFolders.new
      # Instantiate the vagrant provision class
      @provisioners = VenvProvision::Provision.new
      # Instantiate the vagrant hardware class
      @controls = VenvMachine::Controls.new 
      # Instantiate the vagrant linked machines class
      @linked_machines = VenvLinked::Machine.new

    end

    def down(node_object, machine)

      @controls.halt(node_object, machine)

    end

    def up(node_object, node_set=nil, config=nil, machine=nil)

      # Remind me to specify libvirt hypervisor if we're on non-windows OS
      if [!$platform.is_windows, $debug].all?
        $logger.warn($warnings.libvirt_windows_os)
      end
      
      # Define boot timeout
      config.vm.boot_timeout = node_object['boot_timeout'] if node_object.key?('boot_timeout')
      # Define box download behavior
      config.vm.box_download_insecure = $vagrant.box_download_insecure
      # Configure hardware
      @hardware.configure(config, node_object, machine)
      # Configure networking
      @network.configure(config, node_set, node_object, machine)
      # Configure vagrant synced folders
      @syncedfolders.configure(node_object, machine)
      # Provision Machine if applicable
      no_provision = [
        $no_provision,
        !node_object.key?('provisioners'),
        (ARGV.include?("--no-provision"))
      ].any?
      unless no_provision
        provision(node_object, node_set, machine)
      end
      # Start any linked machines
      if $debug and defined? Pry::rescue  
        Pry::rescue { @linked_machines.up(node_object) }
      else
        @linked_machines.up(node_object) if node_object.dig("linked_machines")
      end
    end

    def provision(node_object, node_set=nil, machine=nil)
      if ARGV.include?('up') and !node_object['is_provisioned']
        @provisioners.run(node_object, node_set, machine)
      elsif  ["provision"].any? { |arg| ARGV.include?(arg) }
        @provisioners.run(node_object, node_set, machine)
      end
    end

  end

  class Group

    def initialize
      require 'common'     
      @node = VenvCommon::CLI.new      
    end    

    def up(node_set)
      if $node_group
        all_groups = (node_set.map { |node| [node["groups"]] })
        if !all_groups.include?($node_group)
          $logger.error($errors.group.not_found % $node_group)
          abort
        end
        $logger.info($info.group.up % $node_group)
        node_set.each do |node_object|
          if node_object['groups'].include?($node_group)
            @node.up_singleton(node_object, no_provision: ($no_provision or false))
          end
        end
      end
    end

  end

end

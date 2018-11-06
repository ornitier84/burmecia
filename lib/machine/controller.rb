module VenvMachine


  class Controller

    def initialize
      
      # Load libraries
      require 'environment/keys'
      require 'machine/linker'
      require 'provisionment/main'
      require 'machine/config'
      require 'network/configure'
      # Instantiate the vagrant network class
      @keys = VenvEnvironmentKeys::Keys.new
      @network = VenvNetwork::Config.new
      # Instantiate the vagrant hardware class
      @_machine = VenvMachineConfig::Config.new
      # Instantiate the vagrant provision class
      @provisionment_tasks = VenvProvisionment::Main::Tasks.new
      # Instantiate the vagrant linked machines class
      @linked_machines = VenvLinked::Machine.new

    end

    def down(node_object, machine)

      if ARGV.include?("halt")
        $logger.info($info.boot_halt % node_object['name'])
      elsif ARGV.include?("destroy")
        $logger.info($info.boot_destroy % node_object['name'])
      end

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
      @_machine.configure_hardware(config, node_object, machine)
      # Configure networking
      @network.configure(config, node_set, node_object, machine)
      # Configure vagrant synced folders
      @_machine.configure_synced_folders(node_object, machine)
      # Provision Machine if applicable
      no_provision = [
        $no_provision,
        !node_object.key?('provisioners'),
        (ARGV.include?("--no-provision"))
      ].any?
      unless no_provision
        provision(node_object, config, node_set, machine)
      end
      # Start any linked machines
      if $debug and defined? Pry::rescue  
        Pry::rescue { @linked_machines.up(node_object) }
      else
        @linked_machines.up(node_object) if node_object.dig("linked_machines")
      end
    end

    def provision(node_object, config=nil, node_set=nil, machine=nil)
      if [
        (ARGV.include?('up') and !node_object['is_provisioned']),
        $vagrant_args.include?("provision")
      ].any?
        # Insert environment-specific keys
        @keys.insert(config, node_object, 
          $environment_private_key_file, 
          $environment_public_key_file, 
          $environment_authorized_keys_file)       
        @provisionment_tasks.run(node_object, node_set, machine)
      end
    end

  end

  class Group

    def initialize
      require 'util/controller'     
      @node = VenvUtilController::Controller.new      
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

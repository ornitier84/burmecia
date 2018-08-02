module VenvCLI

  class LinkedMachines

    def initialize
      require_relative 'common'     
      @node = VenvCommon::CLI.new
    end

    def up(node_object)
      linked_machines = [node_object.key?("linked_machines"),!node_object["linked_machines"].nil?].all? ?
      node_object["linked_machines"] : []
      linked_machines.each do |m|
        @node.up_singleton({'name' => "#{m}"})
      end
    end
  end

  class Node

    def initialize
      if !$manged
        require_relative 'networking'
        require_relative 'machine'
        require_relative 'managed'
      end
      require_relative 'common'     
      require_relative 'provision'      
      if $managed
        # Instantiate the vagrant managed node class 
        @managed_node = VenvManaged::Node.new
        # Instantiate the vagrant linked machines class 
        @linked_machines = LinkedMachines.new
        # Instantiate the vagrant common class 
        @snode = VenvCommon::CLI.new      
      else         
        # Instantiate the vagrant network class 
        @network = VenvNetworking::Network.new
        # Instantiate the vagrant hardware class 
        @hardware = VenvMachine::Hardware.new
        # Instantiate the vagrant syncedfolders class 
        @syncedfolders = VenvMachine::SyncedFolders.new
        # Instantiate the vagrant linked machines class 
      end
      @linked_machines = LinkedMachines.new      
      # Instantiate the vagrant provision class 
      @provisioners = VenvProvision::Provision.new      
      # Instantiate the vagrant hardware class 
      @node = VenvMachine::Controls.new    
    end

    def down(node_object, machine)
      @node.halt(node_object, machine)
    end

    def up(node_object, node_set=nil, config=nil, machine=nil)
      # Remind me to specify libvirt hypervisor if we're on non-windows OS
      if [!$platform.is_windows, $debug].all?
        $logger.warn($warnings.libvirt_windows_os)
      end   
      if $managed
        status = get_managed_state(node_object)
        if status.to_s != 'reachable'
          $logger.error($errors.managed.not_reachable % node_object['name'])
          return false
        end
        if $platform.is_windows
          ansible_surrogate = node_set.select { |k, v| k['name'] == $ansible.surrogate}.first
          if ansible_surrogate.key?('managed') and !ansible_surrogate['managed'].nil?
            ansible_surrogate_status = get_managed_state(ansible_surrogate)
          else
            ansible_surrogate_status = @snode.status_singleton(ansible_surrogate)
          end
          if ansible_surrogate_status.to_s != 'reachable'
            $logger.error($errors.managed.surrogate.not_reachable % $ansible.surrogate)
            return false
          end
        end          
      else       
        # Configure hardware
        @hardware.configure(config, node_object, machine)
        # Configure networking
        @network.configure(config, node_set, node_object, machine)
        # Configure vagrant synced folders
        @syncedfolders.configure(node_object, machine)
      end
      # Provision Machine if applicable
      no_provision = [$no_provision, node_object['provision'] == 'false', (ARGV.include? "--no-provision")].any?
      unless no_provision
        if $managed
          provision(node_object)
        else
          provision(node_object, machine)
        end
      end
      # Start any linked machines
      @linked_machines.up(node_object)        
    end

    def provision(node_object, machine=nil)
      machine_dir = "#{Dir.pwd}/#{$vagrant.local_data_dir}/machines/#{node_object['name']}/#{$provider_name}"
      is_provisioned = File.exist?("#{machine_dir}/action_provision")
      if ARGV.include? 'up' and !is_provisioned
        @provisioners.run(node_object, machine) 
      elsif  ["provision", "reload"].any? { |arg| ARGV.include? arg }
        @provisioners.run(node_object, machine)
      end
    end

    def get_managed_state(node_object)
      # printf "%-#{10}s %s\n", 'machine', 'state'
      state = @managed_node.stat(node_object)
      # printf "%-#{10}s %s\n", node_object['name'], status.to_s
      return state
    end

    def stat(node_object, node_set_managed)
      max_name_length = 25
      node_set_managed.each do |_node_object|
        max_name_length = _node_object['name'].length if _node_object['name'].length > max_name_length
      end
      status = get_managed_state(node_object)
      puts "#{node_object['name'].ljust(max_name_length )} #{status.to_s}"
    end    

  end

  class Group

    def initialize
      require_relative 'common'     
      @node = VenvCommon::CLI.new      
    end    

    def up(node_set)
      if $node_group
        all_groups = (node_set.map {|n| [n["groups"]]})
        if !all_groups.include?($node_group)
          $logger.error($errors.group.not_found % $node_group)
          exit
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

  class Inventory

    def initialize()
      require_relative 'inventory'
      @inventory = VenvInventory::Inventory.new
    end
    
    def create(environment)
      if [$environment_context != 'all', (ARGV.include? 'inventory')].all?
        begin
          @inventory.write(environment)
        rescue Exception => e
          $logger.error($errors.inventory.file.error % e)
        end
        exit
      end      
    end

  end

end
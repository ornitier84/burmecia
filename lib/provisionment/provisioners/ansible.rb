module VenvProvisionersAnsible

    def initialize
      require 'provisionment/workers/ansible'
      require 'util/controller'     
      @node = VenvUtilController::Controller.new
      @ansible_settings = VenvProvisionersAnsibleWorker::Settings.new
      @playbook = VenvProvisionersAnsibleWorker::Playbook.new
    end

    def ansible(node_object, provisioner, node_set=nil, machine=nil)
      #####
      # Determine the ansible provisioner
      ansible_provisioner = $platform.is_windows ? "ansible_local" : "ansible"
      ansible_is_local = $platform.is_windows ? true : false
      if provisioner.dig("inventory")
        if $platform.is_windows
          @inventory = provisioner['inventory'].start_with?('/') ?
          provisioner['inventory'] :
          "#{$vagrant.basedir.windows}/#{provisioner['inventory']}"
        else
          @inventory = provisioner['inventory'].start_with?('/') ?
          provisioner['inventory'] :
          "#{$vagrant.basedir.posix}/#{provisioner['inventory']}"
        end
      else
        @inventory = $platform.is_windows ?
        "#{$vagrant.basedir.windows}/#{$vagrant.local_data_dir}/provisioners/ansible/inventory/vagrant_ansible_inventory" :
        "#{$vagrant.basedir.posix}/#{$vagrant.local_data_dir}/provisioners/ansible/inventory/vagrant_ansible_inventory"
      end
      # 'controller' mode logic
      controller_mode = [$managed, $ansible.mode == 'controller'].any?
      if controller_mode
        #####
        if node_object['name'] == $ansible.surrogate
          if $managed and !$managed_node_set.empty?
            $node_subset += $managed_node_set
          end
          if $node_subset.length > 1
            _node_subset = $node_subset.select { |k, v| k['name'] != $ansible.surrogate }
          else
            _node_subset = $node_subset
          end
                # Write scratch playbook(s)
          playbooks = []
          _node_subset.each do |_node|
            ansible_hash = _node['provisioners'].select{ 
              |item| item.keys().first == 'ansible' }.first
                  playbooks.push(@playbook.write(_node, ansible_hash['ansible'])) if !ansible_hash.nil?
          end
          if !playbooks.empty?
            $logger.info($info.provisioners.ansible.controller % { 
              machines: _node_subset.map { |s| "- #{s['name']}" }.join("\n"), 
              ansible_surrogate: $ansible.surrogate
              }
            )         
            @ansible_playbook = @playbook.write_set(playbooks)
            machine.vm.provision ansible_provisioner do |ansible|
              ansible.limit = "all"
              ansible.playbook = @ansible_playbook
              ansible.inventory_path = @inventory
              if defined? Pry::rescue and $debug
                Pry.rescue do
                  @ansible_settings.eval_ansible(node_object, ansible, local: ansible_is_local)
                end
              else
                @ansible_settings.eval_ansible(node_object, ansible, local: ansible_is_local)
              end
            end
          end
        #####
        elsif [$node_subset.length == 1, $vagrant_args.last == $ansible.surrogate].all?
        #####
          ansible_hash = node_object['provisioners'].select{ 
            |item| item.keys().first == 'ansible' }.first
          machine.vm.provision ansible_provisioner do |ansible|
            ansible.playbook = @playbook.write(node_object, ansible_hash['ansible'])['playbook']
            ansible.inventory_path = @inventory
            ansible.groups = @group_set if @group_set
            if defined? Pry::rescue and $debug
              Pry.rescue do
                @ansible_settings.eval_ansible(node_object, ansible, local: ansible_is_local)
              end
            else
              @ansible_settings.eval_ansible(node_object, ansible, local: ansible_is_local)
            end
          end
        end
        #####
      #####
      else
        ansible_hash = node_object['provisioners'].select{ |item| item.keys().first == 'ansible' }.first
        machine.vm.provision ansible_provisioner do |ansible|
          ansible.playbook = @playbook.write(node_object, ansible_hash['ansible'])['playbook']
          ansible.inventory_path = @inventory
          ansible.groups = @group_set if @group_set
          if defined? Pry::rescue and $debug
            Pry.rescue do
              @ansible_settings.eval_ansible(node_object, ansible, local: ansible_is_local)
            end
          else
            @ansible_settings.eval_ansible(node_object, ansible, local: ansible_is_local)
          end
        end       
      end
      #####

    end 

end

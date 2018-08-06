module VenvProvisionersAnsible

  require 'yaml'

  class Playbook

    def create_var_folder(var_path)
      if not File.exist?(var_path)                  
        FileUtils::mkdir_p var_path
      end
    end

    def write(host, provisioner)

      # Determine var folder
      vagrant_ansible_var_folder_real_path = "#{$ansible.vardir % host}"
      # Determine main vagrant_sync folder
      sync_dir = $platform.is_windows ? $vagrant.windows_vagrant_synced_folder_basedir : "#{Dir.pwd()}"
      # Create node-specific ansible var folder
      create_var_folder(vagrant_ansible_var_folder_real_path)

      # Write the main playbook
    ######Check for playbook specification#BEGIN
      if provisioner['ansible'].key?("playbooks") and !provisioner['ansible']['playbooks'].nil?
          playbooks = provisioner['ansible']['playbooks']
          playbook_list = []
          # Read playbook specification 
          ######Parse Playbooks#BEGIN
          case playbooks
          when Array
            playbooks.each do |playbook_item|
              if playbook_item.respond_to?(:values)
                playbook_path = playbook_item.values[0]
              else
                playbook_path = playbook_item
              end
              playbook_path = playbook_path.start_with?('/') ? 
              playbook_path : "#{sync_dir}/#{$ansible_basedir}/playbooks/#{playbook_path}"
              if playbook_item.respond_to?(:keys)
                playbook_option = {playbook_item.keys[0] => playbook_path} 
              else
                playbook_option = { $ansible.default_include_statement => playbook_path }
              end
              playbook_list.push(playbook_option)
            end
          when String
              playbook_path = playbooks.start_with?('/') ? 
              playbooks : "#{sync_dir}/#{$ansible_basedir}/#{playbooks}"                    
            playbook_list = [{$ansible.default_include_statement => playbook_path}]
          else
            playbook_list = []
          end
          ######Parse Playbooks#END
          dynamic_playbook = _write(host, provisioner['ansible'])
          playbook_list.push({$ansible.default_include_statement => dynamic_playbook})
          playbook_obj = playbook_list
        else
          # Write the dynamic playbook
          dynamic_playbook = _write(host, provisioner['ansible'])
          playbook_obj = [{$ansible.default_include_statement => dynamic_playbook}]
      end 
    ######Check for playbook specification#END
      case playbook_obj
      when Array 
        playbook_hash = playbook_obj.to_yaml(line_width: -1)
      else
        playbook_hash = ''
      end
      
      main_playbook_file = "#{vagrant_ansible_var_folder_real_path}/main.yaml"
      
      $logger.info "Writing #{main_playbook_file}" if @debug

      File.open(main_playbook_file,"w") do |file|
        file.write playbook_hash
      end
      
      # Define the main playbook from the vm perspective
      vagrant_ansible_var_folder = "#{sync_dir}/#{vagrant_ansible_var_folder_real_path}"
      
      $logger.info "#{vagrant_ansible_var_folder}/main.yaml" if @debug
      
      return "#{vagrant_ansible_var_folder}/main.yaml"  
    end

    def _write(host, ansible_hash_value)

      ansible_hash = ansible_hash_value.clone
      # TODO 
      # Conform to DRY Method
      # Determine var folder
      vagrant_ansible_var_folder_real_path = "#{$ansible.vardir % host}"
      # Determine main vagrant_sync folder
      sync_dir = $platform.is_windows ? $vagrant.windows_vagrant_synced_folder_basedir : "./"

      # Create node-specific ansible var folder
      create_var_folder(vagrant_ansible_var_folder_real_path)
      
      playbook_hash = { 'hosts' => host }
      # YAML representation:
      # vars:
      #   VAGRANT_SYNCED_DIR: some/path  
      # construct the ansible vars hash
      if ansible_hash.key?('vars') and !ansible_hash['vars'].nil?
        case ansible_hash['vars']
        when Hash
          default_vars_hash = {
            'VAGRANT_SYNCED_DIR' => sync_dir,
            'environment_basedir' => $environment.basedir,
            'environment_context' => $environment.context
          }
          vars_hash = {'vars' => default_vars_hash.merge!(ansible_hash['vars']) }
        when Array
          default_vars_hash = { 'vars' =>
            [
              {'VAGRANT_SYNCED_DIR' => sync_dir,
              'environment_basedir' => $environment.basedir,
              'environment_context' => $environment.context
              }
            ]
          }
          vars_hash = {'vars' => default_vars_hash['vars'].concat(ansible_hash['vars'])}
        end
        ansible_hash.delete("vars")
      end
      # Remove the inventory key if it's present, as this is not a 
      # playbook feature
      ansible_hash.delete("inventory") if ansible_hash.key?('inventory')
      ansible_hash.delete("playbooks") if ansible_hash.key?('playbooks')
      case ansible_hash
      when Hash
        merged_ansible_hash = vars_hash.is_a?(Hash) ? 
          vars_hash.merge!(ansible_hash) : ansible_hash
        merged_playbook_hash = [ { 'hosts' => host }.merge!(merged_ansible_hash) ]
        # Define the dynamic playbook from the host perspective
        playbook_file = "#{vagrant_ansible_var_folder_real_path}/dynamic_playbook.yaml"
        File.open(playbook_file,"w") do |file|
          file.write merged_playbook_hash.to_yaml(line_width: -1)
        end
        # Define the dynamic playbook from the vm perspective
        vagrant_ansible_var_folder = "#{sync_dir}/#{vagrant_ansible_var_folder_real_path}"
        return "dynamic_playbook.yaml"    
      else
        raise("This #{ansible_hash} ... is not a HASH")
      end
    end    
  end


end
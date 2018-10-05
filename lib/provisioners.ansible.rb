module VenvProvisionersAnsible

  require 'yaml'

  class Settings

    def eval_ansible(node_object, ansible, local: false)

      # per-machine ansible options
      if node_object.key?("ansible") and !node_object['ansible'].nil?
          node_object['ansible'].each_pair do |item, value|
          ansible.send("#{item}=", value)
        end
      end

      # ansible_local options
      if local
        if $ansible.options.local.respond_to?(:each_pair)
          $ansible.options.local.each_pair do |item, value|
            if !value.nil?
              if node_object.key?("ansible") and !node_object['ansible'].nil?
                if !node_object["ansible"].key?(item.to_s)
                  ansible.send("#{item}=", value)
                end
              else
                ansible.send("#{item}=", value)
              end
            end
          end
        end
        end

      # ansible global options
      if $ansible.options.global.respond_to?(:each_pair)
        $ansible.options.global.each_pair do |item, value|
          if !value.nil?
            if node_object.key?("ansible") and !node_object['ansible'].nil?
              if !node_object["ansible"].key?(item.to_s)
                ansible.send("#{item}=", value)
              end
            else
              ansible.send("#{item}=", value)
            end
          end
        end
      end

    end

  end  

  class Playbook

    def initialize()

      @sync_dir = $platform.is_windows ? '.' : $vagrant.basedir.posix

    end

    def create_var_folder(var_path)
      if not File.exist?(var_path)
        FileUtils::mkdir_p var_path
      end
    end

    def write_set(playbook_files)

      playbook_content = ""
      playbook_files.each do |item|
        playbook_content += "- #{$ansible.default_include_statement}: #{item['playbook']} hosts=#{item['host']}\n"
      end
      playbook_file = "#{@sync_dir}/#{$ansible.paths.playbooks.set}"
      $logger.info "Writing #{playbook_file}" if $debug
      begin
        File.open(playbook_file, "w") do |file|
          file.write playbook_content
        end
      rescue Exception => e
         $logger.error($errors.fso.operations.failure % e)
         abort
      end
      return playbook_file

    end
    

    def write(host, provisioner)

      # Determine var folder
      vagrant_ansible_var_folder_real_path = "#{$ansible.vardir % host['name']}"
      # Determine main vagrant_sync folder
      sync_dir = $platform.is_windows ? $vagrant.basedir.windows : $vagrant.basedir.posix
      # Create node-specific ansible var folder
      create_var_folder(vagrant_ansible_var_folder_real_path)

      # Write the main playbook
    ######Check for playbook specification#BEGIN
      if provisioner.key?("playbooks") and !provisioner['playbooks'].nil?
          playbooks = provisioner['playbooks']
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
          scratch_playbook = _write(host, provisioner)
          playbook_list.push({$ansible.default_include_statement => scratch_playbook})
          playbook_obj = playbook_list
        else
          # Write the scratch playbook
          scratch_playbook = _write(host, provisioner)
          playbook_obj = [{$ansible.default_include_statement => scratch_playbook}]
      end 
    ######Check for playbook specification#END
      case playbook_obj
      when Array 
        playbook_hash = playbook_obj.to_yaml(line_width: -1)
      else
        playbook_hash = ''
      end
      
      # Copy any machine-specific playbooks to the ansible scratch space
      # TODO Move away from copying file objects, 
      # and instead program a set of logic to 
      # dynamiclally reference these files
      ansible_extra_objects_dir = "#{host['node_definition_path']}/#{host['name']}"
      if [File.exist?(ansible_extra_objects_dir), File.directory?(ansible_extra_objects_dir)].all?
        begin
          FileUtils.cp_r(ansible_extra_objects_dir, vagrant_ansible_var_folder_real_path)
        rescue Exception => e
          $logger.error($errors.fso.operations.failure % e)
        end
      else
          $logger.warn($warnings.provisioners.fso.not_found % ansible_extra_objects_dir) if $debug
      end

      # Write the main playbook file
      main_playbook_file = "#{vagrant_ansible_var_folder_real_path}/main.yaml"
      
      $logger.info "Writing #{main_playbook_file}" if $debug

      begin
        File.open(main_playbook_file,"w") do |file|
          file.write playbook_hash
        end
      rescue Exception => e
         $logger.error($errors.fso.operations.failure % e)
      end
      
      # Define the main playbook from the vm perspective
      vagrant_ansible_var_folder = "#{sync_dir}/#{vagrant_ansible_var_folder_real_path}"
      
      $logger.info "#{vagrant_ansible_var_folder}/main.yaml" if @debug
      
      return { 
        "playbook" => "#{vagrant_ansible_var_folder}/main.yaml",
        "host" => host['name']
      }

    end

    def _write(host, ansible_hash_value)

      ansible_hash = ansible_hash_value.clone
      # TODO 
      # Conform to DRY Method
      # Determine var folder
      vagrant_ansible_var_folder_real_path = "#{$ansible.vardir % host['name']}"
      # Determine main vagrant_sync folder
      sync_dir = $platform.is_windows ? $vagrant.basedir.windows : $vagrant.basedir.posix

      # Create node-specific ansible var folder
      create_var_folder(vagrant_ansible_var_folder_real_path)
      
      # playbook_hash = { 'hosts' => host['name'] }
      
      # Construct the ansible vars hash
      # YAML representation:
      # vars:
      #   vagrant_basedir: some/path
      default_vars_hash = {
        'vagrant_basedir' => sync_dir,
        'environment_basedir' => $environment.basedir,
        'environment_context' => $environment.context,
        'keys_dir' => "#{$environment.basedir}/ssh"
      }      
      if ansible_hash.key?('vars') and !ansible_hash['vars'].nil?
        case ansible_hash['vars']
        when Hash
          vars_hash = {'vars' => default_vars_hash.merge!(ansible_hash['vars']) }
        when Array
          default_vars_hash = { 'vars' =>
            [ default_vars_hash ]
          }
          vars_hash = {'vars' => default_vars_hash['vars'].concat(ansible_hash['vars'])}
        end
        ansible_hash.delete("vars")
      else
        ansible_hash['vars'] = default_vars_hash
      end
      # Remove the inventory key if it's present, as this is not a 
      # playbook feature
      ansible_hash.delete("inventory") if ansible_hash.key?('inventory')
      ansible_hash.delete("playbooks") if ansible_hash.key?('playbooks')
      case ansible_hash
      when Hash
        merged_ansible_hash = vars_hash.is_a?(Hash) ? 
          vars_hash.merge!(ansible_hash) : ansible_hash
        merged_playbook_hash = [ { 'hosts' => host['name'] }.merge!(merged_ansible_hash) ]
        # Define the scratch playbook from the host perspective
        playbook_file = "#{vagrant_ansible_var_folder_real_path}/#{$ansible.scratch.playbook_name}"
        File.open(playbook_file,"w") do |file|
          file.write merged_playbook_hash.to_yaml(line_width: -1)
        end
        # Define the scratch playbook from the vm perspective
        vagrant_ansible_var_folder = "#{sync_dir}/#{vagrant_ansible_var_folder_real_path}"
        return $ansible.scratch.playbook_name
      else
        raise("This #{ansible_hash} ... is not a HASH")
      end
    end    
  end


end

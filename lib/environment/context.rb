module VenvEnvironment

class Context

  def initialize
    require 'util/yaml'
    @env_config = YAMLTasks.new
  end

  def join(environment_context)
    
    # Determine environment path
    environment_path = "#{$environment.basedir}/#{environment_context}"
    # Load environment-specific config, initialize variables in global scope
    environment_config_file = "#{environment_path}/config.yaml"
    if File.exist?(environment_config_file)
      begin
        @env_config.parse(environment_config_file, 'settings')
      rescue Exception => e
        $logger.error($errors.environment.config % [environment_config_file, e])
      end
    end
  end

  def get
    
    # Determine environment context (if applicable)
    if File.exist?($environment.context_file)
      environment = File.read($environment.context_file).chomp()
    else
      $logger.warn($warnings.context.environment.no_active % $environment.defaults.context)
      environment = $environment.defaults.context
    end        
    # Define environment path
    environment_path = "#{$environment.basedir}/#{environment}"      
    # Safeguard
    if !File.exist?(environment_path)
      $logger.error($errors.environment.path.notfound % { envp: environment_path, env:environment })
      return nil
    else      
      return environment
    end

  end

end

class Nodes

  def initialize
    require 'erb'
    require 'find'
    require 'yaml'
  end
  

  def generate(environment_context, filters: [])
    environment_path = "#{$environment.basedir}/#{environment_context}/#{$environment.nodesdir}"
    # Verify the environment path exists
    environment_path_parent = environment_path.split(File::SEPARATOR).first
    exclude_paths = Regexp.union($environment.node.definitions.exclude_paths)
    exclude_files = Regexp.union($environment.node.definitions.exclude_files)
    include_files = Regexp.new($environment.node.definitions.include_files)
    if !File.exist?(environment_path_parent)
      $logger.error($errors.environment.path.notfound % environment_path_parent) if $logger
    end
    if $list_hosts_only
      # Read node yaml definitions
      hosts = []
      Find.find(environment_path) do |machine_definition_file|
        node_folder = File.dirname(machine_definition_file).split(File::SEPARATOR).last
        Find.prune if node_folder.match(exclude_paths)
        next unless machine_definition_file.match(include_files)
        hosts.push(File.basename(machine_definition_file".*"))
      end
      return hosts
    else  
      # Read-in node definitions
      node_set = []
      node_names = []
      # Read node yaml definitions
      Find.find(environment_path) do |machine_definition_file|
        node_folder = File.dirname(machine_definition_file).split(File::SEPARATOR).last
        node_folder_parent = File.dirname(machine_definition_file).split(File::SEPARATOR)[2]
        environment_path_fq = File.expand_path("../..", File.dirname(machine_definition_file))
        # skip anything we don't like, as defined in config.yaml
        if !node_folder.nil?
          Find.prune if node_folder.match(exclude_paths)
        end
        if !node_folder_parent.nil?
          Find.prune if node_folder_parent.match(exclude_paths)
        end
        next unless machine_definition_file.match(include_files)
        next unless !machine_definition_file.match(exclude_files)

        # Derive the machine name from its machine definition file
        machine_name = File.basename(machine_definition_file.split(File::SEPARATOR).last, File.extname(machine_definition_file))
        # start reading through the pruned yaml files
        begin
          node_yaml = YAML.load(ERB.new(File.read(machine_definition_file)).result(binding))
        rescue Exception => e
          $logger.error($errors.definition.yaml_syntax % [machine_definition_file, 'yaml error']) if $logger
          $logger.warn($warnings.definition.skipping % [machine_definition_file, 'yaml error']) if $logger
          next
        end
        unless node_yaml.respond_to?('first')
          $logger.error($errors.definition.yaml_syntax % machine_definition_file) if $logger
          $logger.warn($warnings.definition.skipping % machine_definition_file) if $logger
          next
        end
        # Derive the node definition
        node_definition = node_yaml.first
        if !filters.empty?
          next unless filters.any? { |key| node_definition.key? key }
        end
        $logger.info($info.generic.message % "machine_name for #{node_definition['name']} is #{machine_name}") if $debug and $verbose
        # Each node belongs to at least one group, it's parent folder name
        if node_definition.key?('groups')
          node_definition['groups'].push(node_folder) unless node_definition.include?(node_folder)
        else
          node_definition['groups'] = [node_folder]
        end
        # Populate default node keys
        $vagrant.defaults.nodes.keys.each_pair do |default_key,default_value|
          unless node_definition.key?(default_key)
            node_definition[default_key] = default_value
          end
        end

        # Populate node environment keys
        node_definition['environment_path'] = environment_path_fq
        # Populate node definition key
        node_definition['node_definition_path'] = File.dirname(machine_definition_file)
        # Populate machine path
        node_definition['machine_dir'] = "#{Dir.pwd}/#{$vagrant.local_data_dir}/machines/#{node_definition['name']}/#{$provider_name}"
        # Populate is_created property
        node_definition['is_created'] = File.exist?("#{node_definition['machine_dir']}/id")
        # Populate is_provisioned property
        node_definition['is_provisioned'] = File.exist?("#{node_definition['machine_dir']}/action_provision")
        # intermediary variable node_name
        node_name = node_definition['name']
        # Skip duplicate machine definitions (according to machine 'name' property)
        if node_names.include?(node_name)
          $logger.warn($warnings.definition.skipping % [machine_definition_file, "Duplicate node name: #{node_name}"]) if $logger
          next
        end
        node_names.push(node_name)
        # # Skip unmanaged nodes if managed option specified
        # if [!node_definition.key?('managed'),node_definition['managed'].nil?,$managed].all?
        #   next
        # end
        if node_definition.key?('managed')
          $managed_node_set += node_yaml
        end
        # Skip managed nodes if managed option not specified
         if [node_definition.dig('managed'), !$managed].all?
           next
         end
        # Skip nodes designated as libvirt if that hypervisor is not available
        if [
            $is_vagrant,
            !$is_kvm, 
            node_definition['hypervisor'] == 'libvirt', 
            node_definition.dig('hypervisor')
          ].all?
          $nodes_were_skipped = true
          $logger.warn($warnings.definition.skipping % [machine_definition_file, 'libvirt not available']) if $logger and $debug
          next
        end
        node_set += node_yaml
      end
      $target_all_machines = false
      $node_set = node_set
      # Are we targeting a subset of machines?
      $node_subset = node_set.select { |k, v| ARGV.include?(k['name']) }
      # Ansible 'controller mode' logic
      if [
        [!$node_subset.nil?, !$node_subset.empty?].all?,
        [$managed, $ansible.mode == 'controller'].any?,
        ARGV.include?($ansible.surrogate)
        ].all?
        # TODO
        # Dedupe derivation of ansible_surrogate_object, as it already occurs in cli.rb
        ansible_surrogate_object = $node_subset.select { |k, v| k['name'] == $ansible.surrogate}.first
        if ansible_surrogate_object.nil?
          ansible_surrogate_object = node_set.select { |k, v| k['name'] == $ansible.surrogate}.first
          return $node_subset.push(ansible_surrogate_object)       
        else
          return $node_subset
        end
      else
        if $vagrant_args
		      $target_all_machines = true if $vagrant_args.last == 'provision'
        end
        return node_set
      end

    end

  end

end

class Groups

  def generate(node_set)
    # derives node groups from node definitions
    # e.g.
    # {   "web-servers" => [     "node0",     "node1", "node2"   ] }
    #
    @node_groups = [] # Define an array to hold node groups
    @vagrant_groups = {} # Define an array to hold vagrant groups
    node_set.each do |node_object|
        if node_object.key?('groups')
          node_object['groups'].each do |group|
            node_object['groups'].each do |nodegroup|
              @node_groups.push(nodegroup)
            end
          end
        end
    end
    # Populate node groups
    @node_groups = @node_groups.uniq
    @node_groups.each do |vg|          
      @groupset = []
      node_set.each do |node_object| 
        if node_object.dig('groups')
          node_object['groups'].each do |group|
            @groupset.push(node_object['name']) if vg == group
          end
        end
        @vagrant_groups[vg] = @groupset
      end
    end
    return @vagrant_groups
  end

end

end
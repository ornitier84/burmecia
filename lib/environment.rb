module VenvEnvironment

class Context

  def initialize
    if ARGV[0] == 'environment'
      exit
    end
    require_relative 'misc'
    @env_config = YAMLTasks.new
  end

  def join(environment_context)
    
    # Determine environment path
    environment_path = environment_context == 'all' ?
    $environment.basedir : "#{$environment.basedir}/#{environment_context}"
    
    # Load environment-specific config, initialize variables in global scope
    environment_config_file = "#{environment_path}/config.yaml"
    if File.exist?(environment_config_file)
      begin
        @env_config.join(environment_config_file, 'settings')
      rescue Exception => e
        puts "Not reading environment-specific config #{environment_config_file} due to error in parsing"
      end
    end

  end

  def get()
    
    # Determine environment context (if applicable)
    if File.exist?($environment.context_file)
      environment = File.read($environment.context_file)
      environment_path = environment == 'all' ?
      $environment.basedir : "#{$environment.basedir}/#{environment}"      
      if !File.exist?(environment_path)
        puts 'fuckkkk'
        $logger.error($errors.environment.path.notfound % environment_path)
        exit
      else      
        return environment
      end
    else
      return "all"
    end

  end

  def activate (environment_context, managed: false)
    # Instantiate the vagrant environments nodes class
    nodes = Nodes.new    
    if environment_context == 'all'
      environment_path = "#{$environment.basedir}"
      node_set = nodes.generate(environment_path, managed: managed)
      return node_set      
    else
      environment_path = "#{$environment.basedir}/#{environment_context}/#{$environment.nodesdir}"
      node_set = nodes.generate(environment_path, managed: managed)
      return node_set
    end   
  end

end

class Nodes

  def initialize
    require 'erb'
    require 'find'
    require 'yaml'
  end
  

  def generate(environment_path, list_hosts_only=false, managed: false)
    # Verify the environment path exists
    environment_path_parent = environment_path.split(File::SEPARATOR).first
    exclude_paths = Regexp.union($environment.node.definitions.exclude_paths)
    exclude_files = Regexp.union($environment.node.definitions.exclude_files)
    include_files = Regexp.new($environment.node.definitions.include_files)
    if !File.exist?(environment_path_parent)
      $logger.error($errors.environment.path.notfound % environment_path_parent) if $logger
    end
    if list_hosts_only
      # Read node yaml definitions
      hosts = []
      Find.find(environment_path) do |f|
        node_folder = File.dirname(f).split(File::SEPARATOR)[-1]
        Find.prune if node_folder.match(exclude_paths)
        next unless f.match(include_files)
        hosts.push(File.basename(f,".*"))
      end
      return hosts
    else  
      # Read-in node definitions
      node_set = []
      node_names = []

      # Read node yaml definitions
      Find.find(environment_path) do |f|
        node_folder = File.dirname(f).split(File::SEPARATOR)[-1]
        node_folder_parent = File.dirname(f).split(File::SEPARATOR)[2]
        environment_path_fq = File.expand_path("../..", File.dirname(f))
        # skip anything we don't like, as defined in config.yaml
        if !node_folder.nil?
          Find.prune if node_folder.match(exclude_paths)
        end
        if !node_folder_parent.nil?
          Find.prune if node_folder_parent.match(exclude_paths)
        end
        next unless f.match(include_files)
        next unless !f.match(exclude_files)

        # start reading through the pruned yaml files
        begin
          y = YAML.load(ERB.new(File.read(f)).result)
        rescue Exception => e
          $logger.error($errors.definition.yaml_syntax % [f, 'yaml error']) if $logger
          $logger.warn($warnings.definition.skipping % [f, 'yaml error']) if $logger
          next
        end
        unless y.respond_to?('first')
          $logger.error($errors.definition.yaml_syntax % f) if $logger
          $logger.warn($warnings.definition.skipping % f) if $logger
          next
        end
        node_definition = y.first
        # Each node belongs to at least one group, it's parent folder name
        if node_definition.key?('groups')
          y.first['groups'].push(node_folder) unless node_definition.include?(node_folder)
        else
          y.first['groups'] = [node_folder]
        end
        # Populate default node keys
        $vagrant.defaults.nodes.keys.each_pair do |k,v|
          unless node_definition.key?(k)
            y.first[k] = v
          end
        end
        # Populate node environment keys
        y.first['environment_path'] = environment_path_fq
        # Populate node definition key
        y.first['node_definition_path'] = File.dirname(f)
        node_name = node_definition['name']
        if node_names.include? node_name
          $logger.warn($warnings.definition.skipping % [f, "Duplicate node name: #{node_name}"]) if $logger
          next
        end
        node_names.push(node_name)
        # Skip unmanaged nodes if managed option specified
        if [!node_definition.key?('managed'),node_definition['managed'].nil?,managed, (!ARGV.include? "inventory")].all?
          next
        end
        # Skip managed nodes if managed option not specified
        if [node_definition.key?('managed'),!node_definition['managed'].nil?,!managed, (!ARGV.include? "inventory")].all?
          next
        end
        # Skip nodes designated as libvirt if that hypervisor is not available
        if [
            $is_vagrant,
            !$is_kvm, 
            node_definition['hypervisor'] == 'libvirt', 
            [
              node_definition.key?('hypervisor'),
              !node_definition['hypervisor'].nil?
            ].all?
          ].all?
          $nodes_were_skipped = true
          $logger.warn($warnings.definition.skipping % [f, 'libvirt not available']) if $logger and $debug
          next
        end
        node_set += y
      end
      return node_set

    end

  end

  def create(node_name, node_group, node_environment, node_box, node_size='medium')
    
    @node_name = node_name
    @node_box = node_box
    @node_size = node_size
    groups = Groups.new
    groups.create(node_group, node_environment)
    node_environment_path = "#{$environment.basedir}/#{node_environment}"
    node_group_path = "#{node_environment_path}/#{$environment.nodesdir}/#{node_group}"
    node_yaml = YAML.load(ERB.new(File.read($vagrant.templates.node)).result(binding)).to_yaml(line_width: -1)
    node_yaml_file = "#{node_group_path}/#{node_name}.yaml"
    $logger.info($info.commands.node.create % node_yaml_file)
    begin
      File.open(node_yaml_file,"w") do |file|
        file.write(node_yaml)
      end
    rescue Exception => e
      $logger.error($errors.fso.operations.failure % e)
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
        if node_object.key?('groups')
          node_object['groups'].each do |group|
            @groupset.push(node_object['name']) if vg == group
          end
        end
        @vagrant_groups[vg] = @groupset
      end
    end
    return @vagrant_groups
  end

  def create(group_name, group_environment)
    group_environment_path = "#{$environment.basedir}/#{group_environment}"
    group_path = "#{group_environment_path}/#{$environment.nodesdir}/#{group_name}"
    if !File.exist?(group_path)
      begin 
        FileUtils::mkdir_p group_path
      rescue Exception => e
        $logger.error($errors.fso.operations.failure % e)
      end      
    end
  end


end

end
# Sets environment context for writing inventory yaml file relevant to specified environment
# Load custom libraries
require 'environment/main'
# Instantiate the vagrant environment nodes class
@context = VenvEnvironment::Main.new

@vars_dict = {}
@vars_group = {}

options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant inventory ACTION ENVIRONMENT"
  opt.separator  ""
  opt.separator  "Actions"
  opt.separator  "     create: creates ansible inventory file (inventory.yaml) for specified environment"
  opt.separator  ""
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end
opt_parser.parse!


def get_vars(key, environment_path, vars_type: 'host')
  # Verify the environment path exists
  environment_path_parent = environment_path.split(File::SEPARATOR).first
  warn("#{environment_path_parent} not found") unless File.exist?(environment_path_parent)
  # Read-in node definitions
  _vars = { key => ''}
  # Read node yaml definitions
  Dir.glob(environment_path).each do |f|
    puts "Reading #{f}"
    begin
      y = YAML::load_file(f)
    rescue Exception => e
      $logger.error($errors.definition.yaml_syntax % f)
      $logger.warn($warnings.definition.skipping % f)
      next
    end
    if vars_type == 'host'
      host = File.basename(f,".*")
      host_var = {host => y}
      if @vars_dict[key].is_a?(Hash)
        @vars_dict[key].merge!(host_var)
      else
        @vars_dict.merge!(host_var)
      end
    else
      vars_hash = {'vars' => y}
      if vars_hash['vars'].is_a?(Hash)
        @vars_group.merge!(vars_hash['vars'])
      end
      @vars_dict = {key => @vars_group}
    end
  end
  return @vars_dict
end

def write(environment='all')
  # Define the environment path
  environments_path = environment == 'all' ?
    $environment.basedir : "#{$environment.basedir}/#{environment}"
  if not File.exist?(environments_path)
    $logger.error($errors.inventory.path.notfound % environments_path)
  end
  # Define the load pattern for reading yaml files
  environment_path = "#{$environment.basedir}/#{environment}/#{$environment.nodesdir}"
  # Derive the node/group set
  node_set = @context.generate_nodeset(environment)
  group_set = @context.generate_groupset(node_set)
  #
  # Build the ansible inventory hash
  #
  hosts = Hash[node_set.collect { |item| [item['name'], nil] } ]
  children = Hash[group_set.collect { |item| [item[0], item[1]] } ]
  all = { 'all' => { 
    'hosts' => hosts, 
    'children' => {}
     }
  }
  group_set.collect { |group| 
    all['all']['children'].merge!(group[0] => {})
    all['all']['children'][group[0]]['hosts'] = Hash[group[1].collect {|node| [node, nil] }]
  }
  # Write the ansible inventory file from the yaml-formatted hash
  $logger.info($info.inventory.file.write % "#{environments_path}/inventory.yaml")
  File.open("#{environments_path}/inventory.yaml","w") do |file|
    file.write all.to_yaml(line_width: -1)
  end
  $logger.info($info.completion.done)
end
    

case ARGV[1]
when "create"
  environment_context = ARGV[-1] != 'create' ? ARGV[-1] : 'all'
  if [environment_context != 'all', (ARGV.include? 'inventory')].all?
    begin
      write(environment_context)
    rescue Exception => e
      $logger.error($errors.inventory.file.error % [e, e.backtrace.first.to_s.bold])
    end
    abort
  end      
else
  puts opt_parser
end
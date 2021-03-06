# Manage vagrant machine groups

# Load custom libraries
require 'util/controller'
require 'commands/lib/group.commands'
require 'commands/lib/environment.commands'
require 'environment/main'
# Instantiate the vagrant commands group class
group = VenvCommandsGroup::Commands.new
# Instantiate the vagrant commands environment class
env = VenvCommandsEnvironment::Commands.new
# Instantiate the vagrant environment nodes class
@context = VenvEnvironment::Main.new
cli = VenvUtilController::Controller.new

options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant group ACTION <PARAMS> [OPTIONS]"
  opt.separator  ""
  opt.separator  "Actions"
  opt.separator  "     create: create machine group folder under specified environment"
  opt.separator  "     up: boot up specified machine group under specified environment context"
  opt.separator  ""
  opt.separator  "Options"
  opt.on("-e","--environment ENVIRONMENT","specify the machine's environment context") do |environment|
    options[:environment] = environment
  end 
  opt.on("-n","--no-provision","skip provisionment steps") do |no_provision|
    options[:no_provision] = no_provision
  end
  opt.on("-h","--help","help") do
    puts opt_parser
  end
  opt.separator  ""          
  opt.separator  "Usage Examples:"
  opt.separator  "     vagrant group create mygroup --environment allentown"
  opt.separator  "     vagrant group up mygroup --environment allentown"
  opt.separator  "     vagrant group up mygroup --environment allentown --no-provision"
  opt.separator  ""          
end
opt_parser.parse!

def get_machines(group_environment, machine_group)
  # Generate the node set
  machine_targets = []
  node_set = @context.generate_nodeset(group_environment)
  node_set_filtered = node_set.select { |k, v| k['groups'].include?(machine_group) }
  node_set_filtered.each { |n| machine_targets.push(n['name']) }
  return machine_targets
end

# Quit if environment not specified
if !options.dig(:environment)
  $logger.error($errors.commands.group.noenv)
  puts opt_parser
  exit
end

# Gather variables
machine_group = ARGV[2]
group_environment = options[:environment]

case
when ARGV[1] == "create"
  $logger.info($info.commands.group.create % {group:machine_group, environment: group_environment})
  group.create(machine_group, options[:environment])
when ARGV[1] == "destroy"
  env.activate(group_environment)
  machine_targets = get_machines(group_environment, machine_group)
  cli.run_cmd("vagrant destroy #{machine_targets.join(' ')} --force")
when ARGV[1] == "halt"
  env.activate(group_environment)
  machine_targets = get_machines(group_environment, machine_group)
  cli.run_cmd("vagrant halt #{machine_targets.join(' ')}")
when ARGV[1] == "reload"
  env.activate(group_environment)
  $logger.info($info.commands.group.reload % { group:machine_group, environment: group_environment })
  machine_targets = get_machines(group_environment, machine_group)
  cli.run_cmd("vagrant reload #{machine_targets.join(' ')}")   
when ARGV[1] == "provision"
  # env.activate(group_environment)
  # $logger.info($info.commands.group.provision % { group:machine_group, environment: group_environment })
  @context.join(group_environment)
  machine_targets = get_machines(group_environment, machine_group)
  controller_index = machine_targets.index{ |s| s == $ansible.controller }
  machine_targets.insert(-1, machine_targets.delete_at(controller_index))
  cli.run_cmd("vagrant provision #{machine_targets.join(' ')}")
when ARGV[1] == "status"
  env.activate(group_environment)
  $logger.info($info.commands.group.status % { group:machine_group, environment: group_environment })
  machine_targets = get_machines(group_environment, machine_group)
  cli.run_cmd("vagrant status #{machine_targets.join(' ')}")  
when ARGV[1] == "up"
  env.activate(group_environment)
  $logger.info($info.commands.group.up % {group:machine_group, environment: group_environment})
  machine_targets = get_machines(group_environment, machine_group)
  $logger.info($debugging.commands.group.up % { group:machine_group, environment: group_environment, machines:machine_targets.join(' ') }) if $debug
  cli.run_cmd("vagrant up #{machine_targets.join(' ')}")
else
  puts opt_parser
end
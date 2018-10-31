# Manage vagrant machines
# Load custom libraries
require 'commands/lib/group.commands'
group = VenvCommandsGroup::Commands.new

options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant machine ACTION [OPTIONS]"
  opt.separator  ""
  opt.separator  "Actions"
  opt.separator  "     create: create machine definition as per specification"
  opt.separator  ""
  opt.separator  "Options"
  opt.on("-b","--box BOX","specify the machine vagrant box") do |box|
    options[:box] = box
  end                                                 
  opt.on("-e","--environment ENVIRONMENT","specify the machine's environment context") do |environment|
    options[:environment] = environment
  end  
  opt.on("-g","--group GROUP","specify the machine's group") do |group|
    options[:group] = group
  end 
  opt.on("-n","--name MACHINE_NAME","specify the machine name") do |name|
    options[:name] = name
  end 
  opt.on("-s","--size SIZE","specify the machine size (small, medium, large, xlarge)") do |size|
    options[:size] = size
  end 
  opt.separator  "Options"
  opt.on("-b","--box BOX","specify the machine vagrant box") do |box|
    options[:box] = box
  end           
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end
opt_parser.parse!

case

when [ARGV[1] == "create", 
options.dig(:environment), 
options.dig(:group),
options.dig(:name)
].all?
  @machine_name = options[:name]
  @machine_box = options.dig(:box) ? options[:box] : $vagrant.defaults.nodes.keys.box
  @machine_size = options.dig(:size) ? options[:size] : $vagrant.defaults.nodes.size
  @boot_timeout = $vagrant.defaults.config.boot_timeout
  machine_environment = options[:environment]
  machine_group = options[:group]
  group.create(machine_group, machine_environment)
  machine_environment_path = "#{$environment.basedir}/#{machine_environment}"
  machine_group_path = "#{machine_environment_path}/#{$environment.nodesdir}/#{machine_group}"
  machine_yaml = YAML.load(ERB.new(File.read($vagrant.templates.node)).result(binding)).to_yaml(line_width: -1)
  machine_yaml_file = "#{machine_group_path}/#{@machine_name}.yaml"
  $logger.info($info.commands.node.create % machine_yaml_file)
  begin
    File.open(machine_yaml_file,"w") do |file|
      file.write(machine_yaml)
    end
  rescue Exception => e
    $logger.error($errors.fso.operations.failure % e)
  end

else
  puts opt_parser
end

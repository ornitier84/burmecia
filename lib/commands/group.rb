# Call vagrant commands against specified node groups
require 'open3'
$no_provision = false
group = VenvEnvironment::Groups.new
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
  opt.on("-N","--no-provision","skip provisionment steps") do |no_provision|
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
case
when [ARGV[1] == "create",
options.key?(:environment)].all?
  node_group = ARGV[2]
  group.create(node_group, options[:environment])
when [ARGV[1] == "up", options.key?(:environment)].all?
  node_group = ARGV[2]
  no_provision = options.key?(:no_provision) ? '--no-provision' : ''
  puts "Bringing up node group #{node_group} under environment #{options[:environment]}!"
  Vagrant::Util::Subprocess.execute(VenvCommon::CLI.vagrant_cmd, 'environment', 'activate', options[:environment])
else
  puts opt_parser
end  
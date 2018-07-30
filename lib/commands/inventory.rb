# Sets environment context for writing inventory yaml file relevant to specified environment
$environment_context = "all";
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
case ARGV[1]
when "create"
  $environment_context = ARGV[2]
else
  puts opt_parser
end
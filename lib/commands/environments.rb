# Specifies environment context for vagrant operations
$environment_context = "all";
options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant environment ACTION [OPTIONS]"
  opt.separator  ""
  opt.separator  "Actions"
  opt.separator  "     activate: activate specified environment"
  opt.separator  "     list: lists available environments"
  opt.separator  ""
  opt.separator  "Options"
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end
opt_parser.parse!
case ARGV[1]
when "activate"
  $environment_context = ARGV[2]
when "list"
  Dir.glob("#{$environment.basedir}/*").select {
    |f| 
    puts f if File.directory?(f)
  }
else
  puts opt_parser
end
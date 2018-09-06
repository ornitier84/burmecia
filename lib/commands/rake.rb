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
when "init"
  require 'open3'
  bin_path = Vagrant::Util::Which.which("rake").split(File::SEPARATOR).first
  rake_exe = "#{bin_path}\\rake"
  ruby_exe = "#{bin_path}\\ruby.exe"
  cmd = "#{ruby_exe} #{rake_exe} init"
  puts "Run this command: #{cmd}"
else
  puts opt_parser
end
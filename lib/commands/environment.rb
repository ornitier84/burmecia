# Sets environment context for vagrant operations
# Load custom libraries
require 'util/prompt'
require 'commands/lib/environment.commands'
require 'util/fso'
# Instantiate the vagrant commands environment class
env = VenvCommandsEnvironment::Commands.new

environment_context = "all";
options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant environment ACTION [OPTIONS]"
  opt.separator  ""
  opt.separator  "Actions"
  opt.separator  "     activate: activate specified environment"
  opt.separator  "     create: create environment folder and skeleton"
  opt.separator  "     initialize: initialize specified environment"
  opt.separator  "     list: lists available environments"
  opt.separator  "     remove: remove environment folder"
  opt.separator  ""
  opt.separator  "Options"
  opt.on("-f","--force","Force intended action") do |force|
    options[:force] = true
  end   
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end
opt_parser.parse!
case ARGV[1]
when "activate"
  environment = ARGV.last
  env.activate(environment)
when "create"
  environment_context = ARGV.last
  environment_folder = "#{$environment.basedir}/#{environment_context}"
  if File.exist?(environment_folder)
    abort "Abort. Existing environment folder found: #{environment_folder}"
  end
  puts "Creating:"
  $environment.skeleton.each do |directory|
    dirobj = "#{environment_folder}/#{directory}"
    puts dirobj
    fso_mkdir(dirobj)
  end  
when "initialize"
  # Initialize environment keys
  environment_context = ARGV.last
  environment_path = "#{$environment.basedir}/#{environment_context}"
  if env.initialize_config(environment_context) and env.initialize_keys(environment_context)
    fso_write("#{environment_path}/#{$semaphores.environment.initialized}", "true")
    puts 'Done!'
  else
    puts "I encountered a problem initializing environment #{environment_context}"
  end
when "list"
  $logger.info($info.commands.environment.args.list.listing)
  Dir.glob("#{$environment.basedir}/*").select {
    |f| 
    puts f if File.directory?(f)
  }
  $logger.info($info.commands.environment.args.list.active % env.get)
when "remove"
  prompt = VenvUtilPrompt::Prompt.new
  environment_context = ARGV.last
  environment_folder = "#{$environment.basedir}/#{environment_context}"
  unless options.key?(:force)
    abort("aborted!") if prompt.ask("Are you sure you want to remove and delete #{environment_folder}?", ['y', 'n']) == 'n'
  end
  puts "Removing #{environment_folder}"
  puts "Done!" if fso_rmtree(environment_folder)
else
  puts opt_parser
end

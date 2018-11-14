# Manage project

# Load custom libraries
require 'commands/lib/environment.commands'
require 'project/requirements'
require 'util/controller'
require 'util/prompt'
require 'util/yaml'
cli = VenvUtilController::Controller.new
# Instantiate vagrant commands class for environment tasks
env = VenvCommandsEnvironment::Commands.new
# Instantiate vagrant environment main class for contextual tasks
@context = VenvEnvironment::Main.new

options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant project ACTION ENVIRONMENT"
  opt.separator  ""
  opt.separator  "Actions"
  opt.separator  "     setup: Installs all project requirements"
  opt.separator  "     test: Run vagrant tests ala Rakefile"
  opt.separator  ""
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end
opt_parser.parse!

def assert_execution(condition)
  if (condition)
    puts "OK"
  else
    puts "FAILED"
  end
end

case ARGV[1]
  when "setup"
    # Load main config
    config = YAMLTasks.new
    config.parse('etc/config.yaml', 'settings')
    current_context = env.get
    @context.join(current_context)
    ## Required plugins
    missing_plugins = VenvProjectRequirements::VenvPlugins.check_plugins
    if $platform.is_windows and !missing_plugins.empty?
      vagrant_path_patterns = Regexp.union($vagrant.commands.project.path_patterns)
      vagrant_paths = ENV['PATH'].split(';').select { |p| p.match(vagrant_path_patterns) }
      if vagrant_paths
        ENV['PATH'] = vagrant_paths.join(';')
      else
        $logger.error($errors.commands.project.no_path_detected)
        abort
      end
    end    
    missing_plugins.each do |plugin|
      system("vagrant plugin install #{plugin}")
    end
  when "shutdown"
    # Shutdown and (if applicable) delete all machines in current environment
    prompt = VenvUtilPrompt::Prompt.new
    abort("Aborted!") if prompt.ask("Are you sure you want to shutdown and delete all of your defined machine?", ['y', 'n']) == 'n'
    cmd = "vagrant destroy --force"
    cli.run_cmd(cmd)    
  when "test"
    ## "Run tests"
    puts "Running vagrant tests ..."
    starttime = Time.now
    timestamp = starttime.utc.strftime('%Y%m%d%H%M%S')
    environment_context_file = ".vagrant/tmp/.environment_context"
    current_context = env.get
    _environment = { "VAGRANT_DOTFILE_PATH" => ".vagrant/dummy-#{timestamp}" }
    puts "Testing environment create"
    system("vagrant environment create dummy-#{timestamp}")
    puts "Testing environment activate"
    system("vagrant environment activate dummy-#{timestamp}")
    puts "Testing node create"
    system("vagrant machine create -e dummy-#{timestamp} -n dummy-#{timestamp} -g dummy")
    puts "Testing vagrant inventory create"
    system("vagrant inventory create dummy-#{timestamp}")
    puts "Testing vagrant status"
    system(_environment, "vagrant status")
    puts "Testing vagrant up"
    system(_environment, "vagrant up dummy-#{timestamp}")
    puts "Testing vagrant halt"
    system(_environment, "vagrant halt dummy-#{timestamp}")
    puts "Testing vagrant destroy with --force"
    system(_environment, "vagrant destroy dummy-#{timestamp} --force")
    machine_dotfile_path = File.expand_path("../.vagrant/dummy-#{timestamp}")
    puts "Removing machine dotfile path #{machine_dotfile_path}"
    puts "Removing dotfile path #{machine_dotfile_path}"
    puts "Failed to remove #{machine_dotfile_path}!" if !fso_rmtree(machine_dotfile_path)
    puts "Restoring original environment context"
    system("vagrant environment activate #{current_context}")
    puts "Testing vagrant environment remove with --force"
    system("vagrant environment remove dummy-#{timestamp} --force")
    endtime = Time.now
    t = endtime - starttime
    puts "project tests took %s seconds to complete" % t
else
  puts opt_parser
end
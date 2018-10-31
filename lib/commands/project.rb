# Manage project

# Load custom libraries
require 'util/controller'
require 'util/prompt'
require 'util/yaml'
cli = VenvUtilController::Controller.new

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
    ## Required plugins
    required_plugins = $project.requirements.plugins.mandatory
    if $platform.is_linux
      required_plugins += $project.requirements.plugins.libvirt
    elsif [$platform.is_windows,$platform.is_osx].any?
      required_plugins += $project.requirements.plugins.virtualbox
    end
    if not required_plugins.empty?
      required_plugins.each do |plugin|
        puts "Run `vagrant plugin install #{plugin}`"
        # process = Vagrant::Util::Subprocess.execute(
        #   "vagrant",
        #   "plugin", 
        #   "install",
        #    plugin
        #   )
        # puts process.stdout if process.stdout        
        # puts process.stderr if process.stderr        
      end
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
    environment_context_file = ".vagrant/.environment_context"
    current_context = File.read(environment_context_file) rescue 'all'
    puts "Testing environment create"
    system("vagrant environment create dummy-#{timestamp}")
    puts "Testing environment activate"
    system("vagrant environment activate dummy-#{timestamp}")
    puts "Testing node create"
    system("vagrant machine create -e dummy-#{timestamp} -n dummy-#{timestamp} -g dummy")
    puts "Testing vagrant inventory create"
    system("vagrant inventory create dummy-#{timestamp}")
    puts "Testing vagrant status"
    system("vagrant status")
    puts "Testing vagrant up"
    system("vagrant up dummy-#{timestamp}")
    puts "Testing vagrant halt"
    system("vagrant halt dummy-#{timestamp}")
    puts "Testing vagrant destroy with --force"
    system("vagrant destroy dummy-#{timestamp} --force")
    machine_folder = File.expand_path("../.vagrant/machines/dummy-#{timestamp}", __FILE__)
    puts "Removing machine folder #{machine_folder}"
    begin
      FileUtils::rmtree machine_folder if File.exist?(machine_folder)
    rescue Exception => e
      system("Failed to remove #{machine_folder}!")
    end
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
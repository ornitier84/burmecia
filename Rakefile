require 'erb'
require 'yaml'

task :default => ["init"]

# alias
task :i => :init
task :u => :destroy

task :init do
	require_relative 'lib/misc'
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
			system("vagrant plugin install #{plugin}")
		end
	end	
end

desc "Shutdown and (if applicable) delete all machines in current environment"
task :destroy do
  require_relative 'lib/common'
  prompt = VenvCommon::Prompt.new
  abort("rake aborted!") if prompt.ask("Are you sure you want to shutdown and delete all of your defined machine?", ['y', 'n']) == 'n'
  system("vagrant destroy --force")
end

desc "say hello"
task :hello do
  system("echo hello")
end

desc "Run tests"
task :tests do
  system("echo Running vagrant tests ...")
  timestamp = Time.now.utc.strftime('%Y%m%d%H%M%S')
  environment_context_file = ".vagrant/.environment_context"
  current_context = File.read(environment_context_file) rescue 'all'
  system("echo Testing environment create")
  system("vagrant environment create dummy-#{timestamp}")
  system("echo Testing environment activate")
  system("vagrant environment activate dummy-#{timestamp}")
  system("echo Testing node create")
  system("vagrant node create -e dummy-#{timestamp} -n dummy-#{timestamp} -g dummy")
  system("echo Testing vagrant inventory create")
  system("vagrant inventory create dummy-#{timestamp}")
  system("echo Testing vagrant status")
  system("vagrant status")
  system("echo Testing vagrant up")
  system("vagrant up dummy-#{timestamp}")
  system("echo Testing vagrant halt")
  system("vagrant halt dummy-#{timestamp}")
  system("echo Testing vagrant destroy with --force")
  system("vagrant destroy dummy-#{timestamp} --force")
  system("echo Testing vagrant environment remove with --force")
  system("vagrant environment remove dummy-#{timestamp} --force")
  system("echo activating previously active environment")
  system("vagrant environment activate #{current_context}")
end

def assert_execution(condition)
  if (condition)
    puts "OK"
  else
    puts "FAILED"
  end
end
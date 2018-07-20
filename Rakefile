require 'erb'
require 'yaml'

task :default => ["init"]

# alias
task :i => :init
task :u => :destroy

task :init do
	require_relative 'lib/yaml.misc'
	# Platform
	host_os = RbConfig::CONFIG['host_os'] # e.g. /darwin/, /linux/, /mingw/ (Windows cygwin)
	platform_is_osx = true if host_os =~ /darwin/ || nil
	platform_is_linux = true if host_os =~ /linux/ || nil
	platform_is_windows = true if host_os =~ /mingw/ || nil	
	# Load main config
	config = YAMLTasks.new
	config.parse('etc/vagrant.config.yaml', 'settings')	
	## Required plugins
	required_plugins = []
	if $platform.is_linux
		required_plugins = $project.requirements.plugins['libvirt']
	elsif [$platform.is_windows,$platform.is_osx].any?
		required_plugins = $project.requirements.plugins['virtualbox']
	end
	if not required_plugins.empty?
		required_plugins.each do |plugin|
			system("vagrant plugin install #{plugin}")
		end
	end	
end

task :destroy do
  abort("rake aborted!") if ask("Are you sure you want to shutdown and delete all of your defined machine?", ['y', 'n']) == 'n'
  system("vagrant destroy --force")
end

desc "Run tests"
task :tests do
  system("echo Running vagrant tests ...")
  system("vagrant status")
end

def assert_execution(condition)
  if (condition)
    puts "OK"
  else
    puts "FAILED"
  end
end

def get_stdin(message)
  print message
  STDIN.gets.chomp
end

def ask(message, valid_options)
  if valid_options
    answer = get_stdin("#{message} #{valid_options.to_s.gsub(/"/, '').gsub(/, /,'/')} ") while !valid_options.include?(answer)
  else
    answer = get_stdin(message)
  end
  answer
end
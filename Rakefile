require 'erb'
require 'yaml'

task :default => ["init"]

# alias
task :i => :init
task :u => :destroy

task :init do
	require 'lib/misc'
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


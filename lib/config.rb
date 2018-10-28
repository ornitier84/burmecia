# Load built-in libraries
require 'erb'
require 'log4r/config'
require 'vagrant/ui'
require 'yaml'
# Load custom modules
require 'misc'
require 'formatter'
# Load main config
vagrant_config_file = File.expand_path('../../etc/config.yaml', __FILE__)
vagrant_locale_file = File.expand_path('../../etc/locales/en.yaml', __FILE__)
# Initialize config loader
config = YAMLTasks.new
# Load language locale, initialize variables in global scope
config.parse(vagrant_locale_file, 'strings')
# Load config, initialize variables in global scope
config.parse(vagrant_config_file, 'settings')
# Logging
$debug = [
	(ARGV.include?('--debug')), 
	ENV['DEBUG'], ENV['debug'], 
	$logging.debug, 
	File.exist?($semaphores.debug)
	].any?
# Instantiate the logger method
$logger = Vagrant::UI::Colored.new
# Initialize global variables
# Managed nodes
$managed_node_set = []
$managed = true if ARGV.index{ |s| s.include?("--managed-targets=") }
# Hypervisors
$is_virtualbox = defined?('VagrantPlugins::ProviderProviderVirtualBox') ? true : false
$is_kvm = defined?('VagrantPlugins::ProviderLibvirt') ? true : false
$provider_name = $is_kvm ? 'libvirt' : 'virtualbox'
# Create required file paths
paths = [$logging.logs_dir]
paths.each do |directory|
  begin 
  	FileUtils::mkdir_p directory if not File.exist?(directory)
  rescue Exception => e
    $logger.error($errors.fso.operations.failure % e)
  end
end
## Required plugins
@required_plugins = []
missing_plugins = []
@required_plugins = $project.requirements.plugins['libvirt'] if $platform.is_linux
@required_plugins = $project.requirements.plugins['virtualbox'] if $platform.is_windows or $platform.is_osx
$project.requirements.plugins.mandatory.each do |plugin|
	@required_plugins.push(plugin)
end
if not @required_plugins.empty?
	@required_plugins.each do |plugin|
	  unless Vagrant.has_plugin?(plugin)
	    missing_plugins.push(plugin)
	  end
	end
	if not missing_plugins.empty?
	  $logger.error($warnings.missing_plugin)
	  missing_plugins.each do |p|
		$logger.warn($warnings.missing_plugin_install % p)
	  end
	end
end

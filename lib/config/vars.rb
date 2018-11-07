require 'util/fso'
include VenvUtilFSO 

# Logging
$debug = [
	(ARGV.include?('--debug')), 
	ENV['DEBUG'], ENV['debug'], 
	$logging.debug, 
	File.exist?($semaphores.debug)
	].any?
$verbose = [
	(ARGV.include?('--verbose')), 
	ENV['VERBOSE'], ENV['verbose'], 
	$logging.verbose, 
	File.exist?($semaphores.verbose)
	].any?
# Instantiate the logger method
$logger = Vagrant::UI::Colored.new
# Initialize global variables
# Managed nodes
$managed_node_set = []
$managed = true if ARGV.index{ |s| s.include?("--managed-targets=") }
# Hypervisors
$is_virtualbox = defined?(VagrantPlugins::ProviderVirtualBox) ? true : false
$is_kvm = defined?(VagrantPlugins::ProviderLibvirt) ? true : false
$provider_name = $is_kvm ? 'libvirt' : 'virtualbox'
# Create required file paths
paths = [
	$logging.logs_dir,
	$vagrant.tmpdir
]
if Dir.pwd == $_VAGRANT_PROJECT_ROOT
	paths.each do |directory|
	  fso_mkdir(directory)
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
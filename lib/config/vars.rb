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
# Quit if we detect more than one vagrant provider installed/enabled
abort($errors.vagrant.multiple_providers) if [$is_virtualbox, $is_kvm].all?
# Derive provider name
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

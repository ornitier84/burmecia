# Load built-in libraries
require 'erb'
require 'log4r/config'
require 'vagrant/ui'
require 'yaml'
# Load custom modules
require_relative 'misc'
require_relative 'formatter'
# Instantiate the pretty_print text formatter handler
@pretty_print = VenvFormatter::PrettyPrint.new
# Load main config
vagrant_config_file = File.expand_path('../../etc/vagrant.config.yaml', __FILE__)
vagrant_locale_file = File.expand_path('../../etc/locales/en.yaml', __FILE__)
# Initialize config loader
config = YAMLTasks.new
# Load language locale, initialize variables in global scope
config.parse(vagrant_locale_file, 'strings')
# Load config, initialize variables in global scope
config.parse(vagrant_config_file, 'settings')
# Logging
@debug = $debug || ENV['DEBUG'] || ENV['debug'] || $logging.debug || false
$logger = Vagrant::UI::Colored.new
# Create required paths
paths = [$logging.logs_dir]
paths.each do |directory|
  begin 
  	FileUtils::mkdir_p directory if not File.exist?(directory)
  rescue Exception => e
    $logger.error($errors.fso.operations.failure % e)
  end
end
# Vagrant
## Required plugins
@required_plugins = []
missing_plugins = []
@required_plugins = $project.requirements.plugins['libvirt'] if $platform.is_linux
@required_plugins = $project.requirements.plugins['virtualbox'] if $platform.is_windows or $platform.is_osx
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

# Load vagrant plugins
#
# vagrant-hosts plugin
#
begin
	require 'vagrant-hosts' 
rescue Exception => err
  if $debug
    STDERR.puts "Exception: #{err.message}"
    STDERR.puts "Backtrace:\n#{@pretty_print.backtrace(err)}\n"  
  else
    $logger.error($errors.loaderror % err)
  end
end

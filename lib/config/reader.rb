# Load built-in libraries
require 'erb'
require 'log4r/config'
require 'vagrant/ui'
require 'yaml'
# Load custom modules
require 'util/yaml'
# Load main config
vagrant_config_file = File.expand_path('etc/config.yaml', $_VAGRANT_PROJECT_ROOT)
vagrant_locale_file = File.expand_path('etc/locales/en.yaml', $_VAGRANT_PROJECT_ROOT)
# Initialize config loader
config = YAMLTasks.new
# Load language locale, initialize variables in global scope
config.parse(vagrant_locale_file, 'strings')
# Load config, initialize variables in global scope
config.parse(vagrant_config_file, 'settings')

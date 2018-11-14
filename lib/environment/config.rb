module VenvEnvironmentConfig

	require 'util/fso'
	include VenvUtilFSO

	def initialize_config(_environment_context)

		return false if _environment_context.nil?
		@environment_context = _environment_context
		# Derive the path to the public key file
		config_dir = File.join($environment.basedir,
		_environment_context)
		# Derive the path to the config file
		env_config_file = File.join(config_dir, "/config.yaml")
		$logger.info($info.environment.config.init % _environment_context)
		unless File.exist?(env_config_file)
			config_yaml = YAML.load(ERB.new(File.read($vagrant.templates.config)).result(binding)).to_yaml(line_width: -1)
			config_yaml_file = "#{$environment.basedir}/#{_environment_context}/config.yaml"
			# Write the config file
			fso_write(config_yaml_file, config_yaml)
		end

		return true

	end

end
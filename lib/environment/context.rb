module VenvEnvironmentContext
  
    require 'util/yaml'

    def join(environment_context)
      
      env_config = YAMLTasks.new
      # Determine environment path
      environment_path = "#{$environment.basedir}/#{environment_context}"
      # Load environment-specific config, initialize variables in global scope
      environment_config_file = "#{environment_path}/config.yaml"
      if File.exist?(environment_config_file)
        begin
          env_config.parse(environment_config_file, 'settings')
        rescue Exception => e
          $logger.error($errors.environment.config % [environment_config_file, e])
        end
      end
    end

    def get
      
      # Determine environment context (if applicable)
      if File.exist?($environment.context_file)
        environment = File.read($environment.context_file).chomp()
      else
        $logger.warn($warnings.context.environment.no_active % $environment.defaults.context)
        environment = $environment.defaults.context
      end        
      # Define environment path
      environment_path = "#{$environment.basedir}/#{environment}"   
      # Safeguards
      unless File.exist?("#{environment_path}/#{$semaphores.environment.initialized}")
        $logger.error($errors.environment.uninitialized % { env: environment })
        return ''
      end

      unless File.exist?(environment_path)
        $logger.error($errors.environment.path.notfound % { envp: environment_path, env:environment })
        return nil
      else      
        return environment
      end

    end

end

module VenvCommandsEnvironment

  class Commands
  
    def activate(environment)

      # Get the environment path
      environment_path = "#{$environment.basedir}/#{environment}"
      $logger.info($info.environment.activate % [environment, $environment.context_file])
      if !File.exist?(environment_path)
        $logger.error($errors.environment.path.notfound %  {env: environment,
          envp: environment_path, cf: $environment.context_file, 
          denv: $environment.defaults.context })
        abort
      else
        File.open($environment.context_file,"w") do |file|
          file.write environment
        end
      end
      $logger.info($info.completion.done)

    end  
  
  end


end
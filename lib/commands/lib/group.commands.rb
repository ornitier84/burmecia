module VenvCommandsGroup

  class Commands
  
    def create(group_name, group_environment)
      group_environment_path = "#{$environment.basedir}/#{group_environment}"
      group_path = "#{group_environment_path}/#{$environment.nodesdir}/#{group_name}"
      if !File.exist?(group_path)
        begin 
          FileUtils::mkdir_p group_path
        rescue Exception => e
          $logger.error($errors.fso.operations.failure % e)
        end      
      end
    end  
  
  end


end
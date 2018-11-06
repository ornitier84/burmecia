module VenvCommandsGroup

  require 'util/fso'

  class Commands
  	
  extend VenvUtilFSO 
  
    def create(group_name, group_environment)
      group_environment_path = "#{$environment.basedir}/#{group_environment}"
      group_path = "#{group_environment_path}/#{$environment.nodesdir}/#{group_name}"
      fso_mkdir(group_path)
    end  
  
  end


end
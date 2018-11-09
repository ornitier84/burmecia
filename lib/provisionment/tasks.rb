module VenvProvisionmentTasks

	# Imports
	require 'provisionment/provisioners/ansible'
	require 'provisionment/provisioners/local'
	require 'provisionment/provisioners/puppet'
	require 'provisionment/provisioners/shell'
	require 'provisionment/provisioners/preflight'

	class Tasks

		include VenvProvisionersAnsible
		include VenvProvisionersLocal
		include VenvProvisionersPuppet
		include VenvProvisionersShell
		include VenvProvisionersPreflight

	    def run(node_object, node_set=nil, machine=nil)

	      invoke_preflight_tasks(node_object, machine)

	      if node_object.dig("provisioners")
	        node_object["provisioners"].each do |provisioner|
	          if not provisioner.is_a?(Hash)
	            $logger.warn($warnings.definition.provisioners.malformed % node_object['name'])
	            next
	          end
	          case
	          when [provisioner.key?('local'), !provisioner['local'].nil?].all?
	            if $debug 
	            	Pry.rescue do
	            		local(node_object)              
	            	end
	            else
            		local(node_object)              
	            end
	          when [provisioner.key?('shell'), !provisioner['shell'].nil?].all?
	            if $debug 
	            	Pry.rescue do
	            		shell(node_object, machine)
	            	end
	            else
	            	shell(node_object, machine)
	            end
	          when [provisioner.key?('ansible'), !provisioner['ansible'].nil?].all?
	            if $debug 
	            	Pry.rescue do
	            		ansible(node_object, provisioner['ansible'], node_set, machine)
	            	end
	            else
	            	ansible(node_object, provisioner['ansible'], node_set, machine)
	            end	            
	          when [provisioner.key?('puppet'), !provisioner['puppet'].nil?].all?
	            if $debug 
	            	Pry.rescue do
		            	puppet(node_object, machine)
	            	end
	            else
	            	puppet(node_object, machine)
	            end
	          else
	            $logger.info($info.no_provisioners % node_object['name'])
	          end   
	        end
	      end      
	    end

	end

end

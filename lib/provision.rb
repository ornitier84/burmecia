module VenvProvision

	class Provision

		# Imports
		require_relative 'provisioners'

		def initialize
		  # Instantiate the vagrant provisioner class 
		  @invoke = VenvProvisioners::Provisioner.new			
		end

	    def run(node_object, node_set=nil, machine=nil)
		  # Skip all provisionment except for ansible if all of the following conditions hold true:
		  # - ansible controller mode is enabled
		  # - vagrant was called using syntax: vagrant provision {{ ansiblesurrogate }} {{ targetnode }}
    	  no_provision_except_ansible = [
    	  	($ansible.mode == 'controller'), 
    	  	(node_object['name'] == $ansible.surrogate), 
    	  	$vagrant_args[0] == 'provision', 
    	  	($vagrant_args[1] == $ansible.surrogate and $vagrant_args[-1] != $ansible.surrogate), 
    	  	!$node_subset.nil?].all?
	      if node_object.key?("provisioners")
	        node_object["provisioners"].each do |provisioner|
	          if not provisioner.is_a?(Hash)
	            $logger.warn($warnings.definition.provisioners.malformed % node_object['name'])
	            next
	          end
	          case
	          when [provisioner.key?('local'),!provisioner['local'].nil?].all?
	          	if !no_provision_except_ansible
		            if $debug 
		            	Pry.rescue do
		            		@invoke.local(node_object)              
		            	end
		            else
	            		@invoke.local(node_object)              
		            end
	        	end
	          when [provisioner.key?('shell'),!provisioner['shell'].nil?].all?
	            if !no_provision_except_ansible
		            if $debug 
		            	Pry.rescue do
		            		@invoke.shell(node_object, machine)
		            	end
		            else
		            	@invoke.shell(node_object, machine)
		            end
	        	end
	          when [provisioner.key?('ansible'),!provisioner['ansible'].nil?].all?
	            if $debug 
	            	Pry.rescue do
	            		@invoke.ansible(node_object, provisioner['ansible'], node_set, machine)
	            	end
	            else
	            	@invoke.ansible(node_object, provisioner['ansible'], node_set, machine)
	            end	            
	          when [provisioner.key?('puppet'),!provisioner['puppet'].nil?].all?
	            if !no_provision_except_ansible
		            if $debug 
		            	Pry.rescue do
			            	@invoke.puppet(node_object, machine)
		            	end
		            else
		            	@invoke.puppet(node_object, machine)
		            end
	            end	            
	          else
	            $logger.info($info.no_provisioners % node_object['name'])
	          end   
	        end
	      end      
	    end

	end

end
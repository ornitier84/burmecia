module VenvProvision

	class Provision

		# Imports
		require 'provisioners'

		def initialize
		  # Instantiate the vagrant provisioner class 
		  @invoke = VenvProvisioners::Provisioner.new			
		end

	    def run(node_object, node_set=nil, machine=nil)
		  # Skip all provisionment except for ansible if ALL of the following conditions hold true:
		  # - ansible controller mode is enabled
		  # - vagrant was called using syntax: vagrant provision {{ targetnode(s) }} {{ ansiblesurrogate }}
		  # OR
		  # - vagrant was called against managed nodes as per roperly formatted cli parameters
    	  provision_except_ansible = [
    	  	($ansible.mode == 'controller'), 
    	  	($node_subset.length > 1), 
    	  	($vagrant_args.last == $ansible.surrogate)
    	  ].all? || [$managed, ($vagrant_args.last == $ansible.surrogate)].all?
	      if node_object.dig("provisioners")
	        node_object["provisioners"].each do |provisioner|
	          if not provisioner.is_a?(Hash)
	            $logger.warn($warnings.definition.provisioners.malformed % node_object['name'])
	            next
	          end
	          case
	          when [provisioner.key?('local'), !provisioner['local'].nil?].all?
	          	unless provision_except_ansible
		            if $debug 
		            	Pry.rescue do
		            		@invoke.local(node_object)              
		            	end
		            else
	            		@invoke.local(node_object)              
		            end
	        	end
	          when [provisioner.key?('shell'), !provisioner['shell'].nil?].all?
	            unless provision_except_ansible
		            if $debug 
		            	Pry.rescue do
		            		@invoke.shell(node_object, machine)
		            	end
		            else
		            	@invoke.shell(node_object, machine)
		            end
	        	end
	          when [provisioner.key?('ansible'), !provisioner['ansible'].nil?].all?
	            if $debug 
	            	Pry.rescue do
	            		@invoke.ansible(node_object, provisioner['ansible'], node_set, machine)
	            	end
	            else
	            	@invoke.ansible(node_object, provisioner['ansible'], node_set, machine)
	            end	            
	          when [provisioner.key?('puppet'), !provisioner['puppet'].nil?].all?
	            unless provision_except_ansible
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

module VenvProvision

	class Provision

		# Imports
		require_relative 'provisioners'

		def initialize
		  # Instantiate the vagrant provisioner class 
		  @invoke = VenvProvisioners::Provisioner.new			
		end

	    def run(node_object, node_set=nil, machine=nil)
	      if node_object.key?("provisioners")
	        node_object["provisioners"].each do |provisioner|
	          if not provisioner.is_a?(Hash)
	            $logger.warn($warnings.definition.provisioners.malformed % node_object['name'])
	            next
	          end
	          case
	          when [provisioner.key?('local'),!provisioner['local'].nil?].all?
	            @invoke.local(node_object)              
	          when [provisioner.key?('shell'),!provisioner['shell'].nil?].all?
	            @invoke.shell(node_object, machine)              
	          when [provisioner.key?('ansible'),!provisioner['ansible'].nil?].all?
	            @invoke.ansible(node_object, node_set, machine)
	          when [provisioner.key?('puppet'),!provisioner['puppet'].nil?].all?
	            @invoke.puppet(node_object, machine)
	          else
	            $logger.info($info.no_provisioners % node_object['name'])
	          end   
	        end
	      end      
	    end

	end

end
module VenvHypervisorProviders

	class VirtualBox

		def configure(machine, node_object, prov, options) 
	        # Set specific provider options
	        machine.vm.provider prov.to_sym do |params|
	          # Loop through provider options
	          options.each do |type, values|
	            # Check if option has suboptions
	            if values.is_a?(Hash) 
	              values.each do |key, value|
	                params.customize [type, :id, "--#{key}", value]
	              end
	            # Set key=value options
	            else
	              params.send("#{type}=", values)
	            end
	          end
	        end		
	    end	
	
	end

	class LibVirt

		def configure(machine, node_object, prov, options)   
	        # Set specific provider options
	        machine.vm.provider prov.to_sym do |params|
	          # Loop through provider options
	          options.each do |type, values|
				  if type == 'disks'
				    type.each do |disk|
				      params.storage :file, :size => disk['size']
				    end
				  end
	              params.send("#{type}=", values)
	          end
	        end		
	    end	
	
	end

end

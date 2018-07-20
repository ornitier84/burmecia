module VagrantProviders

	class Provider

		def configure(config, host)

		    if !host['provider_options'].nil?
		      if host['provider_options'].has_key?('virtualbox') and !host['provider_options']['virtualbox'].nil?
		        # Loop through provders
		        host['provider_options'].each do |prov, options|
		          # Set specific provider options
		          config.vm.provider prov.to_sym do |params|
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
		    end

		end	

	end

end 
module VenvProvisionersShell

	def shell(node_object, machine=nil)
		# Provisioning configuration for shell scripts.
		if node_object.key?("provisioners")
			node_object["provisioners"].each do |provisioner|
				provisioner_name = provisioner.keys.first()
				if provisioner_name == "shell"
					# Check for a script path specification
					if !provisioner[provisioner_name].nil?
						prov_obj = provisioner[provisioner_name]
						case prov_obj
						when Hash
							case
							when prov_obj.key?("path")
								sh_path = prov_obj["path"] || nil 
								sh_name = prov_obj["name"] || sh_path
								sh_args = prov_obj["args"] || ""
								if $managed
				              	    @node.ssh_singleton(
				              	    	node_object,
				              	    	"#{sh_path} #{sh_args}"
			              	    	)										
								else
									machine.vm.provision 'shell' do |sh|
										sh.path = sh_path
										sh.args = sh_args
										sh.name = sh_name     
									end
								end
							when prov_obj.key?("inline")
								if $managed
				              	    @node.ssh_singleton(
			              	    		node_object,
			              	    		prov_obj["inline"]
			              	    	)									
								else
									machine.vm.provision :shell, inline: prov_obj["inline"]
								end
							end
						when String
							if $managed
			              	    @node.ssh_singleton(
			              	    	node_object,
			              	    	prov_obj
		              	    	)
							else
								machine.vm.provision :shell, inline: prov_obj
							end
						end
					end
				end
			end 
		end           	
	end

end
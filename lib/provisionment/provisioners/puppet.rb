module VenvProvisionersPuppet

	def puppet(node_object, machine=nil)
		
		# Provisioning configuration for puppet
		if node_object.key?("provisioners")
			node_object["provisioners"].each do |provisioner|
				provisioner_name = provisioner.keys.first()
				if provisioner_name == "puppet"
					# Check for a script path specification
					if !provisioner[provisioner_name].nil?
						prov_obj = provisioner[provisioner_name]
						case
						when [
							prov_obj.key?("manifests_path"), 
							prov_obj.key?("module_path"), 
							prov_obj.key?("manifest_file")
							].all?
			                  machine.vm.provision :shell, :path => "scripts/puppet.install.sh", name: 'Checking if we need to install puppet...'
			                  machine.vm.provision :puppet do |puppet|
								  puppet.module_path = prov_obj['module_path'].start_with?('/') ? 
		            			  	prov_obj['module_path'] : "#{$puppet.basedir}/#{prov_obj['module_path']}"						
								  puppet.manifests_path = prov_obj['manifests_path'].start_with?('/') ? 
				                  	prov_obj['manifests_path'] : "#{$puppet.basedir}/#{prov_obj['manifests_path']}"			                  
				                  puppet.manifest_file = prov_obj['manifest_file']
				                  puppet.options = "--verbose --trace" if @debug
			              	  end							
						when [prov_obj.key?("environment"), prov_obj.key?("environment_path")].all?
			                  machine.vm.provision :shell, :path => "scripts/puppet.install.sh", name: 'Checking if we need to install puppet...'
			                  machine.vm.provision :puppet do |puppet|
				                  puppet.environment = prov_obj['environment']
				                  puppet.environment_path = prov_obj['environment_path'].start_with?('/') ? 
				                  	prov_obj['environment_path'] : "#{$puppet.basedir}/#{prov_obj['environment_path']}"
				                  puppet.options = "--verbose --trace" if @debug
			              	  end
						end
					end
				end
			end 
		end 

	end		

end
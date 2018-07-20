module VenvProvisioners

	class Provisioner

		def initialize
			require_relative 'common'			
			@node = VenvCommon::CLI.new
		end

		def ansible(node_object, machine=nil)
		      # Imports
		      require_relative 'provisioners.ansible'			
			  # Instantiate the vagrant provisioner class 
			  playbook = VenvProvisionersAnsible::Playbook.new
		      # Provisioning configuration for ansible
		      if node_object.key?("provisioners")
		        node_object["provisioners"].each do |provisioner|
		          provisioner_name = provisioner.keys.first()
		          if provisioner_name == "ansible"
		            ######Inventory Logic#BEGIN
		            # Check for an inventory file specification
		            if provisioner[provisioner_name].key?("inventory")
		                if $platform.is_windows
		                  @inventory = provisioner[provisioner_name]['inventory'].start_with?('/') ? 
		                  provisioner[provisioner_name]['inventory'] :
		                  "#{$vagrant.windows_vagrant_synced_folder_basedir}/#{provisioner[provisioner_name]['inventory']}"
		                else
		                  @inventory = provisioner[provisioner_name]['inventory'].start_with?('/') ? 
		                  provisioner[provisioner_name]['inventory'] :
		                  "./#{provisioner[provisioner_name]['inventory']}"
		                end
		            else
		                @inventory = $platform.is_windows ? 
		                "#{$vagrant.windows_vagrant_synced_folder_basedir}/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory" :
		                "./.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory"
		            end
		            ######Inventory Logic#END
		            ##################################################
		            ######IFWINDOWS#BEGIN
		            # If the virtual host is running a Windows OS, we run ansible locally on the VM
		            # Write the dynamic playbook
		            @playbook = playbook.write(node_object['name'], provisioner)
		            if $platform.is_windows
		              groups = node_object.key?('groups') ? 
		              node_object['groups'].map { |g| "#{g}" }.join(":") : false		              	
		              playbook_args = groups ? 
		              ["--playbook", 
		              "#{@playbook}",
		              "--groups",
		              "#{groups}",
		              "--inventory",
		              "#{@inventory}",
		              "--provisioners_root_dir", 
		              "#{$vagrant.windows_vagrant_synced_folder_basedir}"] : 
		              ["--playbook", 
		              "#{@playbook}",
		              "--inventory",
		              "#{@inventory}", 
		              "--provisioners_root_dir", 
		              "#{$vagrant.windows_vagrant_synced_folder_basedir}"]
		              if $managed
		              	  if $debug
		              	  	puts "Running #{$vagrant.windows_vagrant_synced_folder_basedir}/#{$ansible.windows_helper_script} #{playbook_args.join(' ')}"
		              	  end
		              	  @node.ssh_singleton(
		              	  	{'name' => $ansible.surrogate},
		              	  	"#{$vagrant.windows_vagrant_synced_folder_basedir}/#{$ansible.windows_helper_script} #{playbook_args.join(' ')}"
		              	  	)
		              else
			              machine.vm.provision 'shell' do |sh|
			                sh.path = $ansible.windows_helper_script
			                sh.args = playbook_args
			                sh.name = $ansible.windows_helper_script
			              end
			          end
		            ######IFWINDOWS#END
		            else
		              # If the virtual host is running a Posix-Compliant OS, we run ansible locally on the VM host
		              machine.vm.provision 'ansible' do |ansible|
		                ansible.inventory_path = @inventory if @inventory
		                ansible.config_file = "provisioners/ansible/ansible.cfg"
						# ansible.extra_vars = { clear_module_cache: true, ansible_ssh_user: 'vagrant' }
					    # ansible.raw_ssh_args = '-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o IdentitiesOnly=yes'
		                ansible.playbook = @playbook                
		                ansible.groups = @group_set
		                ansible.become = true
		              end
		          end
		        end
		      end
		    end
		end		

		def local(node_object)
			require 'open3'
			# Provisioning configuration for commands executed in the host context
			is_invoked = ["up", "provision"].any? { |arg| ARGV.include? arg }
			if node_object.key?('provisioners') and !node_object['provisioners'].nil?
				node_object['provisioners'].each do |provisioner|
					provisioner_name = provisioner.keys.first()
					if provisioner_name == 'local'
						# Check for a script path specification
						if !provisioner[provisioner_name].nil? and is_invoked
							prov_obj = provisioner[provisioner_name]
							#TODO - Improve this code block, dedupe, DRY,etc
							case prov_obj
							when Hash
								case
								when prov_obj.key?('path')
									local_sh_path = prov_obj['path'] || nil 
									local_sh_name = prov_obj['name'] || local_sh_path
									local_sh_args = prov_obj['args'] || ''
									$logger.info($info.provisioners.local.w_args % [local_sh_path, local_sh_args])
									stdin, stdout, stderr, wait_thr = Open3.popen3(local_sh_path local_sh_args)
									if wait_thr.value == 0
										$logger.info($info.provisioners.local.ok)
									end
								when prov_obj.key?('inline')							
									$logger.info($info.provisioners.local.inline % 'defined (inline)')
									stdin, stdout, stderr, wait_thr = Open3.popen3(prov_obj['inline'])
									_output = stdout.readlines.collect(&:strip) || 'N/A'
									output = _output.empty? ? 'N/A' : _output
  									errors = stderr.readlines.collect(&:strip)
									if wait_thr.value == 0
										$logger.info($info.provisioners.local.ok % output)
									else
										$logger.info($errors.provisioners.local.failed % errors)
									end
								end
							when String
								# system(prov_obj)
								$logger.info($info.provisioners.local.inline % 'defined (inline)')
								stdin, stdout, stderr, wait_thr = Open3.popen3(prov_obj)
								_output = stdout.readlines.collect(&:strip)
  								output = _output.empty? ? 'N/A' : _output
  								errors = stderr.readlines.collect(&:strip)
								if wait_thr.value == 0
									$logger.info($info.provisioners.local.ok % output)
								else
									$logger.error($errors.provisioners.local.failed % errors)
								end
							end
						end
					end
				end 
			end           	
		end

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

end
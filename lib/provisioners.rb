module VenvProvisioners

	class Provisioner

		def initialize
			require 'provisioners.ansible'
			require 'common'			
			@node = VenvCommon::CLI.new
			@ansible_settings = VenvProvisionersAnsible::Settings.new
			@playbook = VenvProvisionersAnsible::Playbook.new
		end

		def ansible(node_object, provisioner, node_set=nil, machine=nil)
			#####
			# Determine the ansible provisioner
			ansible_provisioner = $platform.is_windows ? "ansible_local" : "ansible"
			if provisioner.dig("inventory")
				if $platform.is_windows
					@inventory = provisioner['inventory'].start_with?('/') ?
					provisioner['inventory'] :
					"#{$vagrant.basedir.windows}/#{provisioner['inventory']}"
				else
					@inventory = provisioner['inventory'].start_with?('/') ?
					provisioner['inventory'] :
					"#{$vagrant.basedir.posix}/#{provisioner['inventory']}"
				end
			else
				@inventory = $platform.is_windows ?
				"#{$vagrant.basedir.windows}/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory" :
				"#{$vagrant.basedir.posix}/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory"
			end
			# 'controller' mode logic
			controller_mode = [$managed, $ansible.mode == 'controller'].any?
			if controller_mode
				#####
				if node_object['name'] == $ansible.surrogate
					if $managed and !$managed_node_set.empty?
						$node_subset += $managed_node_set
					end
					if $node_subset.length > 1
						_node_subset = $node_subset.select { |k, v| k['name'] != $ansible.surrogate }
					else
						_node_subset = $node_subset
					end
		            # Write scratch playbook(s)
					playbooks = []
					_node_subset.each do |_node|
						ansible_hash = _node['provisioners'].select{ 
							|item| item.keys().first == 'ansible' }.first
		            	playbooks.push(@playbook.write(_node, ansible_hash['ansible'])) if !ansible_hash.nil?
					end
					if !playbooks.empty?
						$logger.info($info.provisioners.ansible.controller % { 
							machines: _node_subset.map { |s| "- #{s['name']}" }.join("\n"), 
							ansible_surrogate: $ansible.surrogate
							}
						)					
						@ansible_playbook = @playbook.write_set(playbooks)
						machine.vm.provision ansible_provisioner do |ansible|
							ansible.limit = "all"
							ansible.playbook = @ansible_playbook
							ansible.inventory_path = @inventory
							if defined? Pry::rescue and $debug
								Pry.rescue do
									@ansible_settings.eval_ansible(node_object, ansible, local: true)
								end
							else
								@ansible_settings.eval_ansible(node_object, ansible, local: true)
							end
						end
					end
				#####
				elsif [$node_subset.length == 1, $vagrant_args.last == $ansible.surrogate].all?
				#####
					ansible_hash = node_object['provisioners'].select{ 
						|item| item.keys().first == 'ansible' }.first
					machine.vm.provision ansible_provisioner do |ansible|
					  ansible.playbook = @playbook.write(node_object, ansible_hash['ansible'])['playbook']
					  ansible.inventory_path = @inventory
					  ansible.groups = @group_set if @group_set
					  if defined? Pry::rescue and $debug
						  Pry.rescue do
						  	@ansible_settings.eval_ansible(node_object, ansible, local: true)
						  end
						else
							@ansible_settings.eval_ansible(node_object, ansible, local: true)
					  end
					end
				end
				#####
			#####
			else
				ansible_hash = node_object['provisioners'].select{ |item| item.keys().first == 'ansible' }.first
				machine.vm.provision ansible_provisioner do |ansible|
				  ansible.playbook = @playbook.write(node_object, ansible_hash['ansible'])['playbook']
				  ansible.inventory_path = @inventory
				  ansible.groups = @group_set if @group_set
				  if defined? Pry::rescue and $debug
					  Pry.rescue do
					  	@ansible_settings.eval_ansible(node_object, ansible, local: true)
					  end
					else
						@ansible_settings.eval_ansible(node_object, ansible, local: true)
				  end
				end				
			end
			#####

		end		

		def local(node_object)
			require 'open3'
			# Provisioning configuration for commands executed in the host context
			is_invoked = ["up", "provision"].any? { |arg| ARGV.include? arg }
			unless $managed_nodes
				env_hash = node_object.select { |k| $environment.node.provisioners.env_hash.include?(k) }
			else
				env_hash = {}
			end
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
									stdin, stdout, stderr, wait_thr = Open3.popen3(env_hash, "#{local_sh_path} #{local_sh_args}")
									if wait_thr.value == 0
										$logger.info($info.provisioners.local.ok)
									end
								when prov_obj.key?('inline')							
									$logger.info($info.provisioners.local.inline % 'defined (inline)')
									stdin, stdout, stderr, wait_thr = Open3.popen3(env_hash, prov_obj['inline'])
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
								$logger.info($info.provisioners.local.inline % 'defined (inline)')
								stdin, stdout, stderr, wait_thr = Open3.popen3(env_hash, prov_obj)
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

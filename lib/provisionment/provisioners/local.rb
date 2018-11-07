module VenvProvisionersLocal

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

end
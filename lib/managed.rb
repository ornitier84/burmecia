module VenvManaged

	class Node

		def initialize
			require 'open3'
			require_relative 'networking'
			@port = VenvNetworking::TCP.new
		end

		def stat(host)

			# Initialize preflight checks
			all_checks_pass = false

			#Check for required keys
			missing_keys = []
			$managed_nodes.required_keys.each do |k|
			  unless host.has_key?(k)
			    missing_keys.push(k)
			  end
			end
			unless missing_keys.empty?
			  $logger.error( $errors.managed.missingkey % host['name'])
			  missing_keys.each do |k|
				$logger.warn($errors.managed.missingkeys % k)
			  end
			else
				all_checks_pass = true
			end
			# Check for mandatory ssh private key specification
			if host.key?('ssh_private_key_path')
				ssh_private_key_path = File.expand_path(host['ssh_private_key_path'])
				# Skip managed node if the specified ssh private key does not exist 
				unless File.exist?(ssh_private_key_path)
					$logger.error($errors.managed.ssh_privatekey_notfound % [host['name'], ssh_private_key_path])
					all_checks_pass = false
				end
			else
				all_checks_pass = false
			end
			if host.key?('ip')
				return read_state(host['ip'], host['ssh']['port'])
			else
				return read_state(host['name'], host['ssh']['port'])
			end
			# Define managed node only if all checks passed
			# if all_checks_pass
			# 	node.vm.provider :managed do |managed_config, override|
			# 		override.vm.box = host['box']
			# 		managed_config.server = host['ip']
			# 		override.ssh.username = host['ssh_user']
			# 		override.ssh.port = host['ssh_port']
			# 		override.ssh.private_key_path = ssh_private_key_path
			# 	end 		
			# else
			# 	$logger.info($errors.managed.checks_fail % host['name'])		
			# end

		end

		def read_state(node_address, port)
		  # return 'not reachable' if machine.id.nil?

		  if [ssh_port_open?(node_address, port), is_pingable?(node_address)].all?
		    # @logger.info "#{node_address} is reachable and SSH login OK"
		    return :reachable
		  else
		    if ssh_port_open?(node_address, port)
		      # @logger.info "#{node_address} is reachable, SSH port open (but login failed)"
		      return :reachable
		    else 
		      if is_pingable? node_address
		        # @logger.info "#{node_address} is pingable (but SSH failed)"
		        return :reachable
		      end
		    end
		  end
		  # host is not reachable at all...
		  return :not_reachable
		end

		def is_pingable?(address)
			ping_cmd = $platform.is_windows ? 
			"ping -n 1 #{address} > nul" : "ping -q -c 1 #{address}"
			stdin, stdout, stderr, wait_thr = Open3.popen3(ping_cmd)
			if wait_thr.value == 0
				return true
			else
				return false
			end	  	  
		end

		def ssh_port_open?(address, port)
		  is_port_open?(address, port)
		end

		def is_port_open?(address, port)
		  return @port.scan(address, port)
		end
	end

end

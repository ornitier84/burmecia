module VenvSettings

	class Config
	
		def evaluate(node_object, machine)
			# per-machine config settings
			if node_object.key?("config") and !node_object['config'].nil?
					node_object['config'].each_pair do |item, value|
					machine.vm.send("#{item}=", value)
				end
			end  
			# global config settings
			$vagrant.defaults.config.each_pair do |item, value|
				if !value.nil?
					if node_object.key?("config") and !node_object['config'].nil?
						if !node_object["config"].key?(item.to_s)
							machine.vm.send("#{item}=", value)
						end
					else
						machine.vm.send("#{item}=", value)
					end
				end
			end
		end

	end
	
	class SSH

		def evaluate(node_object, config)
			if ARGV[-2] == 'ssh' and ARGV[-1] != node_object['name']
				return false
			end
			# per-machine ssh settings
			if node_object.key?("ssh") and !node_object['ssh'].nil?
					node_object['ssh'].each_pair do |item, value|
					config.ssh.send("#{item}=", value)
				end
			end  
			# global ssh settings
			$vagrant.ssh.each_pair do |item, value|
				if !value.nil?
					if node_object.key?("ssh") and !node_object['ssh'].nil?
						if !node_object["ssh"].key?(item.to_s)
							config.ssh.send("#{item}=", value)
						end
					else
						config.ssh.send("#{item}=", value)
					end
				end
			end
		end

	end

end
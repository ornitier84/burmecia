module VenvSettings

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
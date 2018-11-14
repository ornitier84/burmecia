module VenvProjectRequirements
    class VenvPlugins
		def self.check_plugins()
			## Required plugins
			missing_plugins = []
			required_plugins = $project.requirements.plugins.mandatory
			if $platform.is_linux
			  required_plugins += $project.requirements.plugins.libvirt
			elsif [$platform.is_windows,$platform.is_osx].any?
			  required_plugins += $project.requirements.plugins.virtualbox
			end
			if not required_plugins.empty?
				required_plugins.each do |plugin|
				  unless Vagrant.has_plugin?(plugin)
				    missing_plugins.push(plugin)
				  end
				end
				return missing_plugins
			end
		end
    end
end
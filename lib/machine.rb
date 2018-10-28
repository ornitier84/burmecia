module VenvMachine

	class SyncedFolders

		def configure(node_object, machine)
			
			if node_object.dig("synced_folder")
			    node_object['synced_folder'].each do |item, folder|
			      if folder.dig('source')
			      	next if !File.exist?(folder['source'])
			        type = folder.dig('type') ? folder['type'] : $vagrant.synced_folder.defaults.type
			        create = folder.dig('create') ? folder['create'] : $vagrant.synced_folder.defaults.create
			        disabled = folder.dig('disabled') ? folder['disabled'] : $vagrant.synced_folder.defaults.disabled
			        # backwards compat: check if using nfs
			        # NFS
			        if $vagrant.synced_folder.defaults.type == 'nfs'
			          nfs_udp = !folder['nfs_udp'].nil? ? folder['nfs_udp'] : $vagrant.synced_folder.defaults.nfs.udp
			          nfs_version = !folder['nfs_version'].nil? ? folder['nfs_version'] : $vagrant.synced_folder.defaults.nfs.version
			          linux_nfs_options = folder.dig('linux__nfs_options') ? folder['linux__nfs_options'] : $vagrant.synced_folder.defaults.nfs.linux.nfs.options
			          machine.vm.synced_folder folder['source'], folder['target'], 
			            type: type, 
			            nfs_udp: nfs_udp
			        # RSYNC
			        elsif type == 'rsync'
			          rsync_args = !folder['rsync__args'].nil? ? folder['rsync__args'] : $vagrant.synced_folder.defaults.rsync.args
			          rsync_auto = !folder['rsync__auto'].nil? ? folder['rsync__auto'] : $vagrant.synced_folder.defaults.rsync.auto
			          rsync_exclude = !folder['rsync__exclude'].nil? ? folder['rsync__exclude'] : $vagrant.synced_folder.defaults.rsync.auto
			          machine.vm.synced_folder folder['source'], folder['target'], 
			            type: type, 
			            create: create,
			            disabled: disabled, 
			            rsync__args: rsync_args, 
			            rsync__auto: rsync_auto, 
			            rsync__exclude: rsync_exclude
			        elsif type == 'smb'
			          mount_options = !folder['mount_options'].nil? ? folder['mount_options'] : $vagrant.synced_folder.defaults.smb.mount_options
			          machine.vm.synced_folder folder['source'], folder['target'], 
			            type: type, 
			            create: create,
			            disabled: disabled,
			            :mount_options => mount_options
			        # No type found, use old method
			        elsif type == 'generic'
			          owner = !folder['owner'].nil? ? folder['owner'] : ''
			          group = !folder['group'].nil? ? folder['group'] : ''
			          mount_options = !folder['mount_options'].nil? ? folder['mount_options'] : $vagrant.synced_folder.defaults.mount_options
			          machine.vm.synced_folder folder['source'], folder['target'], 
			            type: type,
			            create: create,
			            disabled: disabled, 
			            owner: $vagrant.synced_folder.defaults.owner,
			            group: $vagrant.synced_folder.defaults.group,
			            :mount_options => mount_options
			        end
			      end
			    end
			  end		
		end

	end

	class Controls

		def halt(node_object, machine)
		  if ARGV.include?("halt")
		    $logger.info($info.boot_halt % node_object['name'])
		  elsif ARGV.include?("destroy")
		    $logger.info($info.boot_destroy % node_object['name'])
		  end
		end

	end

	class Hardware

		def initialize
			require 'providers'
			@virtualbox = VenvProviders::VirtualBox.new
			@libvirt = VenvProviders::LibVirt.new
		end

		def get_local_resources(platform, resource)
		  platform_commands = {
		    osx: {
		      vcpu: "sysctl -n hw.ncpu",
		      vmem: "sysctl -n hw.memsize | awk '{print $0/1073741824}'"
		      },

		    linux: {
		      vcpu: "nproc",
		      vmem: "grep MemTotal /proc/meminfo | awk '{print $2}'"
		      },

		    windows: {
		      vcpu: 'powershell -Command "(Get-WmiObject Win32_Processor -Property NumberOfLogicalProcessors | Select-Object -Property NumberOfLogicalProcessors | Measure-Object NumberOfLogicalProcessors -Sum).Sum"',
		      vmem: 'powershell -Command "$(Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % {$_.sum})"'
		      }
		  }
		  # powershell may not be available on Windows XP and Vista, so wrap this in a rescue block
		  platform_command = platform_commands[platform.to_sym][resource.to_sym]
		  begin 
		    res = `#{platform_command}`.chomp()
		  rescue Exception => e
		    $logger.error($errors.exec % platform_command)
		    $logger.error($errors.res % resource)
		    $logger.error("Error was #{e}")
		    return nil  
		  end
		  return res.to_i()
		end	

		def configure(config, node_object, machine)
		  # box
		  # vagrant box
		  machine.vm.box_url = node_object['box_url'] if node_object['box_url']
		  # hardware
		  # Calculate the number of CPUs and the amount of RAM the system has,
		    # in a platform-dependent way; further logic below.
		  case
		    when $platform.is_windows
		      _os = 'windows'
		    when $platform.is_linux
		      _os = 'linux'
		    when $platform.is_osx
		      _os = 'osx'
		  end
	      if node_object.dig("provider")
	          begin
		          # Loop through providers
		          node_object['provider'].each do |prov, options|
		            case prov
		          		when 'virtualbox'
		          			@virtualbox.configure(machine, node_object, prov, options)
		          		when 'libvirt'
		          			@libvirt.configure(machine, node_object, prov, options)
		          	end
		          end
		      rescue => e
		      	$logger.error($errors.machine.provider.syntax % e.backtrace.first)
	      	  end

	      end		  

		end	

	end

end

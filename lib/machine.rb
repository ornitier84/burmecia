module VenvMachine

	class SyncedFolders

		def configure(node_object, machine)
			
			# Determine if we should use NFS mounts for Vagrant Synced Folders
			use_nfs = [node_object.key?("use_nfs"),!node_object["use_nfs"].nil?].all? ?
			node_object["use_nfs"] : $vagrant.use_nfs || false
			nfs_mount_options = [node_object.key?("nfs_mount_options"),!node_object["nfs_mount_options"].nil?].all? ?
			node_object["nfs_mount_options"] : $vagrant.nfs_mount_options
			
			# Determine if we should mount the project root to /vagrant
			no_mount_vagrant = [node_object.key?("no_mount_vagrant"),!node_object["no_mount_vagrant"].nil?].all? ?
			node_object["no_mount_vagrant"] : $vagrant.no_mount_vagrant || false
			if use_nfs and !no_mount_vagrant
				machine.vm.synced_folder ".", "/vagrant", nfs: use_nfs, mount_options: nfs_mount_options
			elsif no_mount_vagrant
				machine.vm.synced_folder ".", "/vagrant", disabled: true
			end

			# Mount synced folders as defined in node yaml
			if node_object.key?("synced_folders") and !node_object["synced_folders"].nil?
				node_object["synced_folders"].each do |folders|
					folders.each do |h,f|
						if File.exist?(h)
							if use_nfs
						 		machine.vm.synced_folder h, f, nfs: use_nfs, mount_options: nfs_mount_options
						 	else
						 		machine.vm.synced_folder h, f
							end
						else
							if @debug
								$logger.warn($warnings.synced_folder_not_found % h)
							end
						end
					end
				end
			end

		end

	end

	class Controls

		def halt(node_object, machine)
		  if ARGV.include? "halt"
		    $logger.info($info.boot_halt % node_object['name'])
		  elsif ARGV.include? "destroy"
		    $logger.info($info.boot_destroy % node_object['name'])
		  end
		end

	end

	class Hardware

		def get_local_resources(platform, resource)
		  commands = {
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
		  cmd = commands[platform.to_sym][resource.to_sym]
		  begin 
		    res = `#{cmd}`.chomp()
		  rescue Exception => e
		    $logger.error($errors.exec % cmd)
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
		  vcpu = node_object['vcpu'] || $vagrant.vcpu_minimum || get_local_resources(_os,'vcpu') / $vagrant.vcpu_allocation_ratio
		  vmem = node_object['vmem'] || $vagrant.vmem_minimum || get_local_resources(_os,'vmem') / $vagrant.vmem_allocation_ratio 
		  # If possible, Use same number of CPUs within Vagrant as the system, defaults to specification from vagrant.config.yaml
		  # Use at least a predetermined amount of RAM, see vagrant.config.yaml
		  # Actually provide the computed CPUs/memory to the backing provider		  
		  if $is_virtualbox
			  if $plugin_disksize_available
			  	config.disksize.size = node_object['vmsize'] if node_object.key?('vmsize')
			  end
			  config.vm.provider :virtualbox do |vb|
			    vb.name = node_object['name']
			    vb.cpus = vcpu
			    vb.memory = vmem
			  end

		  end

		  if $is_kvm
			  config.vm.provider :libvirt do |lv|
			    lv.memory = vmem
			    lv.cpus = vcpu
			    lv.machine_virtual_size = node_object['vmsize'] if node_object.key?('vmsize')
			    if node_object.key?('disks') and !node_object['disks'].nil?
			      disks = node_object['disks']
			      disks.each do |disk|
			        lv.storage :file, :size => disk['size']
			      end
			    end
			  end # config.vm.provider

		  end
	
		  # Configure Provider Options
		  require_relative 'providers'
		  provider = VagrantProviders::Provider.new
		  provider.configure(config, node_object)

		end	

	end

end
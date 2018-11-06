module VenvMachineHardware

	require 'hypervisor/providers'

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

	def configure_hardware(config, node_object, machine)
	  _libvirt = VenvHypervisorProviders::LibVirt.new
	  _virtualbox = VenvHypervisorProviders::VirtualBox.new		
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
	          			_virtualbox.configure(machine, node_object, prov, options)
	          		when 'libvirt'
	          			_libvirt.configure(machine, node_object, prov, options)
	          	end
	          end
	      rescue => e
	      	$logger.error($errors.definition.provider.syntax % e.backtrace.first)
      	  end

      end		  

	end	

end
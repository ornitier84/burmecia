module VenvNetworkProvider

    class VagrantPorts

        def forward(host, machine, network_adapters)
          @vm_usable_port_range = ($vagrant.vm_usable_port_range_start..$vagrant.vm_usable_port_range_end)
          port_forwards = host['port_forwards'] if host.key?('port_forwards') # check for host-->guest port forwarding
          case port_forwards
            when Array
              # Port Forwards
              port_forwards.each do |pf|
                machine.vm.network :forwarded_port, \
                                guest: pf['guest'], \
                                host: pf['host'], auto_correct: true, host_ip: "0.0.0.0"
                machine.vm.usable_port_range = @vm_usable_port_range
              end
            # else
            # TODO Allow specification of a global port forward comprised of randomnized host port => fixed guest port
            #   common_port = Integer(port_forwards) if port_forwards
            #   if common_port
            #     machine.vm.network :forwarded_port, guest: common_port, host: common_port, auto_correct: true
            #     machine.vm.usable_port_range = @vm_usable_port_range                         
            #   end
          end 

        end

    end

    class VagrantLibvirt

        def initialize
            @ports = VagrantPorts.new
        end        

        def configure(host, config, machine, network_adapters)
          case network_adapters
          when String || Hash
            $logger.info("Your node's networking YAML structure is not yet implemented #{network_adapters.class} ... skipping")
          when Array
            # Iterate through networks as per settings in machines.yml
            network_adapters.each do |interface|
                ip = interface['ip'] || 'dhcp'
                networking_method = interface['method'] || $vagrant.vm_network_default_mode
                case 
                  when ip == 'dhcp'
                    config.vm.network interface['method'], type: 'dhcp'
                    @ports.forward(host, machine, network_adapters)
                  when networking_method.include?('public')
                    bridged_interfaces = interface['bridged_adapters'] || []
                    bridged_interfaces.each do |bi|
                      bi.each do |h,g|
                        config.vm.network :public_network, ip: ip,
                        :dev => h,
                        :bridge => g,
                        :mode => "bridge",
                        :type => "bridge"
                      end
                    end             
                  else
                    config.vm.network interface['method'], ip: ip
                    @ports.forward(host, machine, network_adapters)
                end     
            end
          else
            config.vm.network $vagrant.vm_network_default_mode, type: "dhcp"
          end
        end

    end

    class VagrantVirtualBox

        def initialize
            @ports = VagrantPorts.new
        end       

        def configure(host, machine, network_adapters)
          case network_adapters
          when String || Hash
            $logger.info("Your node's networking YAML structure is not yet implemented #{network_adapters.class}")
          when Array
            # Iterate through networks as per settings in machines.yml
            network_adapters.each do |interface|
              networking_method = interface['method'] || $vagrant.vm_network_default_mode
              if networking_method != "public_network" # check networking method
                ip = interface['ip'] || 'dhcp' # check for ip (only for non-public network method)
                adapter = Integer(interface['adapter']) if interface.key?('adapter') # check for network adapter index
                mac_address = interface['mac_address'] if interface.key?('mac_address') # check for mac address specification
                if [ip, adapter].all?
                    if mac_address
                      machine.vm.network networking_method, ip: ip, :adapter => adapter, :mac => mac_address
                    else
                      machine.vm.network networking_method, ip: ip, :adapter => adapter
                    end                
                elsif (not ip) and adapter
                    if mac_address
                      machine.vm.network networking_method, type: "dhcp", :adapter => adapter, :mac => mac_address
                    else
                      machine.vm.network networking_method, type: "dhcp", :adapter => adapter
                    end
                elsif ip
                    if mac_address
                      machine.vm.network networking_method, ip: ip, :mac => mac_address
                    else
                      machine.vm.network networking_method, ip: ip
                    end                  
                else
                  machine.vm.network networking_method, type: "dhcp"
                end
                @ports.forward(host, machine, network_adapters)
              elsif networking_method == "public_network"
                bridged_interfaces = interface['bridged_adapters'] || nil
                adapter = Integer(interface['adapter']) if interface.key?('adapter') # check for network adapter index
                mac_address = interface['mac_address'] if interface.key?('mac_address') # check for mac address specification
                if bridged_interfaces
                  if $platform.is_osx
                    bridged_interfaces.each do |ba|
                      bridged_interfaces += ba.collect { |k,v| "#{k}: #{v}" }
                    end
                  else
                    bridged_interfaces = bridged_interfaces.collect {|k,v| "#{k} #{v}"}
                  end
                  if adapter
                    if mac_address
                      machine.vm.network networking_method, bridge: bridged_interfaces, :adapter => adapter, :mac => mac_address
                    else
                      machine.vm.network networking_method, bridge: bridged_interfaces, :adapter => adapter
                    end
                  else
                    if mac_address
                      machine.vm.network networking_method, bridge: bridged_interfaces, :mac => mac_address
                    else
                      machine.vm.network networking_method, bridge: bridged_interfaces
                    end
                  end
                else
                  if adapter
                    machine.vm.network networking_method, :adapter => adapter
                  else
                    machine.vm.network networking_method
                  end
                end
              else
                machine.vm.network $vagrant.vm_network_default_mode, type: "dhcp"
              end
            end
          else
            machine.vm.network $vagrant.vm_network_default_mode, type: "dhcp"
          end
        end 

    end

end

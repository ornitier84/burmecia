module VenvNetworking

  class Network

    def configure(config, node_set, host, machine)

          # Imports
          require_relative 'networking.providers'

          # Configure VM network settings
          network_adapters = host['interfaces'] || nil
          if network_adapters
            if $is_kvm
              # Instantiate the vagrant network/libvirt class 
              vlibvirt = VenvNetworkingProviders::VagrantLibvirt.new    
              vlibvirt.configure(host, machine, network_adapters)
            else
              # Instantiate the vagrant network/virtualbox class 
              vvirtualbox = VenvNetworkingProviders::VagrantVirtualBox.new    
              vvirtualbox.configure(host, machine, network_adapters)
            end
          else
            machine.vm.network $vagrant.vm_network_default_mode, type: "dhcp"
          end

          # Add fqdns to /etc/hots for all defined hosts in node_set
          if $plugin_vagranthosts_available
            config.vm.provision :hosts do |provisioner|
              node_set.each do |h|
                if h.key?('interfaces') and !h['interfaces'].nil?
                  h['interfaces'].each do |interface|
                    provisioner.add_host interface['ip'], [h['name']] if interface['ip'] and interface.is_a?(Hash)
                  end
                end
              end
            end
          end  
                      
    end

  end



  class TCP
    
    def initialize
      require 'socket'
      require 'timeout'      
    end
    
    def scan( ip, port )
      begin
        Timeout::timeout(1) do 
          begin
            s = TCPSocket.new(ip, port)
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            return false
          end
        end
      rescue Timeout::Error
      end

      return false
    end
  end

end
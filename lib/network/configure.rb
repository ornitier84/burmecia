module VenvNetwork

  class Config

    def configure(config, node_set, host, machine)

          # Imports
          require 'network/provider'

          # Configure VM network settings
          if host.dig('interfaces')
            if $is_kvm
              # Instantiate the vagrant network/libvirt class 
              vlibvirt = VenvNetworkProvider::VagrantLibvirt.new    
              vlibvirt.configure(host, config, machine, host['interfaces'])
            else
              # Instantiate the vagrant network/virtualbox class 
              vvirtualbox = VenvNetworkProvider::VagrantVirtualBox.new    
              vvirtualbox.configure(host, machine, host['interfaces'])
            end
          else
            machine.vm.network $vagrant.vm_network_default_mode, type: "dhcp"
          end
          # Add fqdns to /etc/hots for all defined hosts in node_set
          if defined? VagrantHosts::Plugin
            config.vm.provision :hosts do |provisioner|
              $node_set.each do |h|
                if h.dig('interfaces')
                  h['interfaces'].each do |interface|
                    next if interface.fetch('exclude_from_hosts', false)
                    $logger.info($info.provisioners.hosts % [interface['ip'], h['name'],host['name']]) if $debug 
                    if interface.dig('ip') and interface.is_a?(Hash)
                      if interface.dig('dns')
                        aliases = interface['dns'].fetch('aliases', [])
                      else
                        aliases = []
                      end
                      provisioner.add_host interface['ip'], [h['name']] + aliases
                    end
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

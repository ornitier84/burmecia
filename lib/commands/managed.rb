# Manage bare-metal machines

require 'common'
require 'environment'
require 'open3'
require 'networking'
nodes = VenvEnvironment::Nodes.new
@port = VenvNetworking::TCP.new

options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant managed ACTION [OPTIONS]"
  opt.separator  ""
  opt.separator  "Actions"
  opt.separator  "     provision: run provisioners against specified managed machine"
  opt.separator  "     shutdown: shut down specified managed machine"
  opt.separator  "     status: print status of managed machines"
  opt.separator  "     up: boot up specified managed machine (via wake-on-lan packet)"
  opt.separator  ""
  opt.separator  "Options"
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end

opt_parser.parse!

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

def stat(host, skip_checks=false)
  all_checks_pass = false
  unless skip_checks
    #Check for required keys
    host_platform = host.key?('winrm') ? 'windows' : 'posix'
    required_key = $managed_nodes[host_platform].required_key
    if !host.key?(required_key)
      $logger.error( $errors.managed.missingkey % host['name'])
      $logger.warn($errors.managed.missingkeys % required_key)
      return :error
    end
    missing_keys = []
    $managed_nodes[host_platform].required_properties.each do |k|
      unless host[required_key].key?(k)
        missing_keys.push(k)
      end
    end
    unless missing_keys.empty?
      $logger.error( $errors.managed.missingkey % host['name'])
      missing_keys.each do |k|
      $logger.error($errors.managed.missingkeys % "#{required_key} => #{k}")
      return :error
      end
    else
      all_checks_pass = true
    end
    # Check for mandatory ssh private key specification
    # if host.key?('ssh_private_key_path')
    #   ssh_private_key_path = File.expand_path(host['ssh_private_key_path'])
    #   # Skip managed node if the specified ssh private key does not exist 
    #   unless File.exist?(ssh_private_key_path)
    #     $logger.error($errors.managed.ssh_privatekey_notfound % [host['name'], ssh_private_key_path])
    #     all_checks_pass = false
    #   end
    # else
    #   all_checks_pass = false
    # end
  end

  if host.key?('ip')
    return read_state(host['ip'], host[required_key]['port'])
  else
    return read_state(host['name'], host[required_key]['port'])
  end
  
end  


  # Define managed node only if all checks passed
  # if all_checks_pass
  #   node.vm.provider :managed do |managed_config, override|
  #     override.vm.box = host['box']
  #     managed_config.server = host['ip']
  #     override.ssh.username = host['ssh_user']
  #     override.ssh.port = host['ssh_port']
  #     override.ssh.private_key_path = ssh_private_key_path
  #   end     
  # else
  #   $logger.info($errors.managed.checks_fail % host['name'])    
  # end


# Instantiate the vagrant environments context class
context = VenvEnvironment::Context.new
# Get environment context (if applicable)
environment_context = context.get
# Read any environment-specific options
context.join(environment_context)
# Instantiate the vagrant common cli class
cli = VenvCommon::CLI.new
# Args
vagrant_args = ARGV.clone
vagrant_args.delete_if { |arg| arg.include?('--') }
case vagrant_args[1]
when "provision"
  targets = vagrant_args[2]
  cmd = "vagrant --managed-targets=#{targets} provision #{$ansible.surrogate}"
  cli.run_cmd(cmd)
when "status"
  # Generate the node set
  node_set = nodes.generate(environment_context, filters: ['managed'])
  # Print the status header if we're querying node status
  $logger.info($info.managed.status.header)
  max_name_length = 25
  node_set.each do |node_object|
      max_name_length = node_object['name'].length if node_object['name'].length > max_name_length
      status = stat(node_object)
      puts "#{node_object['name'].ljust(max_name_length )} #{status.to_s}"  
      # # Read node autostart option
      # autostart_setting = [node_object.key?('autostart'),!node_object['autostart'].nil?].all? ? node_object['autostart'] : false
      # # Define boot timeout
      # boot_timeout = node_object['boot_timeout'] if node_object.key?('boot_timeout')
      # # Node actions
      # if ["halt", "destroy"].any? { |arg| ARGV.include? arg }
      #   node.down(node_object)
      # elsif ARGV.include? "status"
      #   node.stat(node_object, node_set)
      # elsif ["up", "provision", "reload"].any? { |arg| ARGV.include? arg }
      #   node.up(node_object, node_set)
      # end
  end 

  # def get_managed_state(node_object)
  #   # printf "%-#{10}s %s\n", 'machine', 'state'
  #   state = @managed_node.stat(node_object)
  #   # printf "%-#{10}s %s\n", node_object['name'], status.to_s
  #   return state
  # end

  # def stat(node_object, node_set)
  #   max_name_length = 25
  #   node_set.each do |_node_object|
  #     max_name_length = _node_object['name'].length if _node_object['name'].length > max_name_length
  #   end
  #   status = get_managed_state(node_object)
  #   puts "#{node_object['name'].ljust(max_name_length )} #{status.to_s}"
  # end   
  return

  # status = get_managed_state(node_object)
  # if status.to_s != 'reachable'
  #   $logger.error($errors.managed.not_reachable % node_object['name'])
  #   return false
  # end
  # if $platform.is_windows
  #   if ansible_surrogate.key?('managed') and !ansible_surrogate['managed'].nil?
  #     ansible_surrogate_status = get_managed_state(ansible_surrogate)
  #   else
  #     ansible_surrogate_status = @node.status_singleton(ansible_surrogate)
  #   end
  #   if ansible_surrogate_status.to_s != 'reachable'
  #     $logger.error($errors.provisioners.ansible.surrogate.not_reachable % {machine:$ansible.surrogate})
  #     return false
  #   end
  # end 

  # # $managed = true
  # # $managed_node_args = ARGV.last.split(",") unless ARGV.last == 'status'
  # # Treat managed/bare metal nodes
  # node_set = $managed ? context.activate(environment_context, managed: true) : []
  # if $managed_node_args
  #   if $managed_node_args.length > 0
  #     node_set = node_set.select { |k, v| $managed_node_args.include?(k['name']) }
  #   end
  # end

else
  puts opt_parser
end
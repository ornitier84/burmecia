module VenvCommon

	class String

		def to_bool(s)
		    case s
		    when /^(yes|true|on|1)$/i
		      true
		    when /^(no|false|off|0)$/i
		      false
		    else
		      return s
		  	end
		end
		
	end

	class CLI

	def initialize
	  require 'open3'
      @ssh_cmd = Vagrant::Util::Which.which("ssh")
	end

	def CLI.vagrant_cmd
      @@vagrant_cmd = Vagrant::Util::Which.which("vagrant")
	end

    def up_singleton(node_object, no_provision: false)
      $logger.info($info.boot.up % node_object['name'])
      if no_provision
      	r = Vagrant::Util::Subprocess.execute(CLI.vagrant_cmd, "up", "#{node_object['name']}", "--no-provision")
      else
      	r = Vagrant::Util::Subprocess.execute(CLI.vagrant_cmd, "up", "#{node_object['name']}")
      end
      puts r.stdout.strip!
      puts r.stderr.strip!
    end

    def ssh_singleton(node_object, args='')
        #TODO Dedupe this block
        if $managed and node_object['name'] != $ansible.surrogate
        	if node_object['ssh'].key?('options')
				ssh_options = node_object['ssh']['options'].map { |k| "-o #{k}" }.join (' ')        		
	        else
	        	ssh_options = "-o ''"
	        end
	        ssh_args = [
	      	"#{node_object['ssh']['user']}@#{node_object['name']}",
	      	"-i",
	      	"#{node_object['ssh']['private_key_path']}",
	      	"-p #{node_object['ssh']['port']}",
	      	ssh_options,
	      	"'
	      	'"
	        ].join(' ')
			stdin, stdout, stderr, wait_thr = Open3.popen3(
				"#{$project.ssh.path} #{ssh_args} '#{args}'"
				)
	        _output = stdout.readlines.collect(&:strip) || 'N/A'
	        output = _output.empty? ? 'N/A' : _output
	        errors = stderr.readlines.collect(&:strip)
	        if wait_thr.value == 0
	  	      $logger.info($info.singleton.ssh.ok % output)
	        else
	  	      $logger.error($errors.singleton.ssh.failed % errors)
	  	    end
	    else
	        r = Vagrant::Util::Subprocess.execute(
	      	CLI.vagrant_cmd, 
	      	"ssh", 
	      	"#{node_object['name']}",
	      	"-c",
	      	args
	      	)
	        puts r.stdout.strip!
	        puts r.stderr.strip!    	
	    end
    end
    
	end

end


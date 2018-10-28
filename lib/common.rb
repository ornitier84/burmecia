module VenvCommon

	class Prompt

		def ask(message, valid_options)
		  if valid_options
		    answer = get_stdin("#{message} #{valid_options.to_s.gsub(/"/, '').gsub(/, /,'/')} ") while !valid_options.include?(answer)
		  else
		    answer = get_stdin(message)
		  end
		  answer
		end

		def get_stdin(message)
		  print message
		  STDIN.gets.chomp
		end		

	end

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

	def run_cmd(cmd, env={})
    	#
    	# Launch subprocess
    	#
		Open3.popen3(env, cmd) do |stdin, stdout, stderr|
			stdin.close
			readers = [stdout, stderr]
			while readers.any?
				# Implement IO.select as per
				# https://ruby-doc.org/stdlib-2.1.2/libdoc/open3/rdoc/Open3.html#method-c-popen3
				ready = IO.select(readers, [], readers)
				ready[0].each do |fd|
					if fd.eof?
						fd.close
						readers.delete fd
					else
						line = fd.readline
						puts('' + line.gsub(/\n/,""))
					end
				end
			end
		end
		# ^^^^^^^^^^
	end

    def status_singleton(node_object, no_provision: false)
		r = Vagrant::Util::Subprocess.execute(CLI.vagrant_cmd, "status", "#{node_object['name']}")
		stdout = r.stdout.strip!
		if stdout.match(/#{node_object['name']}#{$misc.patterns.node.up}/)
			return :reachable
		else
			return :not_reachable
		end
    end

    def up_singleton(node_object, no_provision: false)
		$logger.info($info.boot.up % node_object['name'])
		if no_provision
			cmd = "#{CLI.vagrant_cmd} up #{node_object['name']} --no-provision"
		else
			cmd = "#{CLI.vagrant_cmd} up #{node_object['name']}"
		end
		if @debug
			$logger.info($info.singleton.ssh.command % cmd)
		end		
		begin
			run_cmd(cmd)
		rescue Exception => e
			$logger.error($errors.singleton.ssh.failed % e)
		end       
    end

    def ssh_singleton(node_object, args='')
        #TODO Dedupe this block
        if $managed and node_object['name'] != $ansible.surrogate
        	ssh_options =
        	if node_object['ssh'].key?('extra_args')
				node_object['ssh']['extra_args'].map { |k| "-o #{k}" }.join (' ')
	        else
	        	ssh_options = "-o ''"
	        end
	        ssh_args = [
	      	"#{node_object['ssh']['username']}@#{node_object['name']}",
	      	"-i",
	      	"#{node_object['ssh']['private_key_path']}",
	      	"-p #{node_object['ssh']['port']}",
	      	ssh_options,
	      	"'
	      	'" # simulate carriage return # TODO use something more elegant
	        ].join(' ')
      	    cmd = "#{$project.ssh.path} #{ssh_args} '#{args}'"
      	    if $debug
  	    		$logger.info($info.singleton.ssh.command % cmd)
      	    end		
	      	begin
	      		run_cmd(cmd)
			rescue Exception => e
				$logger.error($errors.singleton.ssh.failed % e)
			end 	    	
	    else
	    	# >>>>>>>>>>
	    	cmd = [
	      	CLI.vagrant_cmd, 
	      	"ssh", 
	      	"#{node_object['name']}",
	      	"-c",
	      	"'#{args}'"
	      	].join(' ')
      	    if $debug
  	    		$logger.info($info.singleton.ssh.command % cmd)
      	    end
	      	begin
	      		run_cmd(cmd)
			rescue Exception => e
				$logger.error($errors.singleton.ssh.failed % e)
			end
			# <<<<<<<<<<
	    end
    end
    
	end

end


module VenvEnvironmentKeys

	require 'vagrant/util/keypair'
	require 'util/fso'
	include VenvUtilFSO

	def initialize_keys(_environment_context)

		return false if _environment_context.nil?
		# Derive the path to the public key file
		keys_dir = File.join($environment.basedir,
		_environment_context,
		$environment.keys.keysdir)
		public_key_file = File.join(keys_dir, "/#{_environment_context}.pub")
		# Derive the path to the private key file
		private_key_file = File.join(keys_dir, "/#{_environment_context}")
		# Derive the path to the authorized_keys file
		authorized_keys = File.join(keys_dir, "/authorized_keys")
		unless [public_key_file,private_key_file].map { |_key_file|
			File.exist?(_key_file) }.all?
			# Generate the content for the public/private keys
			_pub, priv, openssh = Vagrant::Util::Keypair.create
			
			# Create the parent directory if necessary
			fso_mkdir(File.dirname(public_key_file))

			# Write the public key file
			fso_write(public_key_file, openssh)

			# Write the private keyfile
			fso_write(private_key_file, priv)

			# Write the authorized_keys file
			fso_write(authorized_keys, openssh)
		end

	end

	class Keys

		def insert(config, node_object, private_key_file, public_key_file, authorized_keys_file)
			require 'util/fso'
			extend VenvUtilFSO			
	          if $environment.keys.insert_keys and !node_object['keys_provisioned']
	            $logger.info($info.environment.keys.insert % node_object['name'])
	            config.vm.provision "file", source: private_key_file, destination: $environment.keys.dest_private_key_file
	            config.vm.provision "file", source: public_key_file, destination: $environment.keys.dest_public_key_file
	            config.vm.provision "file", source: authorized_keys_file, destination: $environment.keys.dest_authorized_keys_file
	            config.vm.provision "shell", inline: $environment.keys.post_commands
	            fso_write("#{node_object['machine_dir']}/keys_provisioned", 'true')
	          end		
		end

	end

end
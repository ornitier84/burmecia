module VenvMachineSyncedFolder

	require 'config/settings'

	def configure_synced_folders(node_object, machine)
		
		def rebuild_synced_folder_args(_args, _options, _sync_type='')
			_options_new = {}
			if _sync_type.empty? and defined?($vagrant.synced_folder.defaults.type)
				_sync_type = $vagrant.synced_folder.defaults.type
			end
			_options_new['type'.to_sym] = _sync_type
			if _options.respond_to?('each')
				_options.each do |key, option|
					_options_new[key.to_sym] = option
				end
				_args.push(_options_new)
				return _args
			end
		end

		def sync_defaults(_machine)
			synced_folder_args = [
				$_VAGRANT_PROJECT_ROOT, 
				$vagrant.synced_folder.defaults.vagrant_target,
				type: ''
			]
			_machine.vm.synced_folder(*synced_folder_args)			
		end

		unless node_object.dig("synced_folder")
			sync_defaults(machine)
			return
		end		

		if node_object['synced_folder'].respond_to?('each')
		    node_object['synced_folder'].each do |item, folder|
		      	
	      		# Skip synced folder item if we don't have both a source and target
		      	next unless [folder.dig('source'), folder.dig('target')].all?
	      		# Skip synced folder item if source does not exist 
	      		# and the option to create is not set
		      	if !File.exist?(folder['source']) and !folder.dig('options', 'create')
		      		$logger.warn($warnings.fso.synced_folder_not_found % folder['source'])
		      		next
		      	end
		      	# Build the sync args
		        sync_type = folder.fetch('type', '')
			    synced_folder_args = [
				  folder['source'],
				  folder['target']
				]
				synced_folder_options = folder.fetch('options', [])
				synced_folder_args = rebuild_synced_folder_args(
					synced_folder_args, 
					synced_folder_options, 
					sync_type)
				# Send the sync args to the machine object
				machine.vm.synced_folder(*synced_folder_args)
			end   
		else
			_sync_defaults(machine)
		end     
	
	end

end

module VenvMachineConfig

	require 'machine/hardware'
	require 'machine/synced'

	class Config

		include VenvMachineHardware
		include VenvMachineSyncedFolder

	end
	
end

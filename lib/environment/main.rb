module VenvEnvironment
  
	require 'environment/context'
	require 'environment/nodes'
	require 'environment/groups'
	require 'environment/keys'

	class Main

		include VenvEnvironmentContext
		include VenvEnvironmentNodes
		include VenvEnvironmentGroups
		include VenvEnvironmentKeys

	end

end
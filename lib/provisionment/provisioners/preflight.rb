module VenvProvisionersPreflight

	require 'util/controller'

	def invoke_preflight_tasks(node_object, machine=nil)
		@controller = VenvUtilController::Controller.new
		Dir.glob("scripts/preflight/*.sh") do |preflight_script|
			
			sh_path = preflight_script
			sh_name = preflight_script
			sh_args = ""
			if $managed
		  	    @controller.ssh_singleton(
		  	    	node_object,
		  	    	"#{sh_path} #{sh_args}"
			    	)
			else
				machine.vm.provision 'shell' do |sh|
					sh.path = sh_path
					sh.args = sh_args
					sh.name = sh_name
				end
			end

		end

	end

end
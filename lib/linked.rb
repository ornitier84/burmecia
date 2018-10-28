module VenvLinked
  
  class Machine

    def initialize
      
      # Load libraries
      require 'common'     
      @node = VenvCommon::CLI.new

    end

    def up(node_object)
      
      if node_object["linked_machines"].is_a?(Array) and !node_object["linked_machines"].empty?
        node_object["linked_machines"].each do |machine|
          $logger.info($info.machine.linked.up % { machine: node_object['name'] } )
          @node.up_singleton({ 'name' => "#{machine}" })
        end
      else
        $logger.warn($warnings.machine.linked.yaml_syntax % { machine: node_object['name'] } )
      end

    end

  end

end
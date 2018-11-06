module VenvEnvironmentGroups

  def generate_groupset(node_set)
    # derives node groups from node definitions
    # e.g.
    # {   "web-servers" => [     "node0",     "node1", "node2"   ] }
    #
    @node_groups = [] # Define an array to hold node groups
    @vagrant_groups = {} # Define an array to hold vagrant groups
    node_set.each do |node_object|
        if node_object.key?('groups')
          node_object['groups'].each do |group|
            node_object['groups'].each do |nodegroup|
              @node_groups.push(nodegroup)
            end
          end
        end
    end
    # Populate node groups
    @node_groups = @node_groups.uniq
    @node_groups.each do |vg|          
      @groupset = []
      node_set.each do |node_object| 
        if node_object.dig('groups')
          node_object['groups'].each do |group|
            @groupset.push(node_object['name']) if vg == group
          end
        end
        @vagrant_groups[vg] = @groupset
      end
    end
    return @vagrant_groups
  end

end
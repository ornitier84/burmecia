# Calls vagrant commands against specified node
node = VenvEnvironment::Nodes.new
options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant node ACTION [OPTIONS]"
  opt.separator  ""
  opt.separator  "Actions"
  opt.separator  "     create: create machine definition as per specification"
  opt.separator  ""
  opt.separator  "Options"
  opt.on("-b","--box BOX","specify the machine vagrant box") do |box|
    options[:box] = box
  end                                                 
  opt.on("-e","--environment ENVIRONMENT","specify the machine's environment context") do |environment|
    options[:environment] = environment
  end  
  opt.on("-g","--group GROUP","specify the machine's group") do |group|
    options[:group] = group
  end 
  opt.on("-n","--name MACHINE_NAME","specify the machine name") do |name|
    options[:name] = name
  end 
  opt.on("-s","--size SIZE","specify the machine size (small, medium, large, xlarge)") do |size|
    options[:size] = size
  end 
  opt.separator  "Options"
  opt.on("-b","--box BOX","specify the machine vagrant box") do |box|
    options[:box] = box
  end           
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end
opt_parser.parse!
case
when [ARGV[1] == "create", 
options.key?(:environment), 
options.key?(:group),
options.key?(:name)
].all?
  box = options.key?(:box) ? options[:box] : $vagrant.defaults.nodes.keys.box
  size = options.key?(:size) ? options[:size] : $vagrant.defaults.nodes.size
  node.create(options[:name], options[:group], 
  options[:environment], box, size)
else
  puts opt_parser
end
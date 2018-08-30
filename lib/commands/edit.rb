# Calls your preferred text editor for modifying project files
options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant edit MACHINE_NAME OBJECT"
  opt.separator  ""
  opt.separator  "Objects"
  opt.separator  "     playbook: opens the machine's dynamic playbook in your project editor"
  opt.separator  "     definition: opens the machine's definition file"
  opt.separator  ""
  opt.separator  "Options"
  opt.on("-e","--environment ENVIRONMENT","specify the machine's environment context") do |environment|
    options[:environment] = environment
  end   
  opt.on("-g","--group GROUP","specify the machine's group") do |group|
    options[:group] = group
  end          
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end
opt_parser.parse!
case
when ARGV[2] == "playbook"
  machine = ARGV[-2]
  file_obj = "./#{$vagrant.local_data_dir}/machines/#{machine}/provisioners/ansible/$ansible.scratch.playbook_name"
when [ARGV[2] == "definition", options.key?(:environment), options.key?(:group)].all?
  file_obj = "#{$environment.basedir}/#{options[:environment]}/#{$environment.nodesdir}/#{options[:group]}/#{ARGV[-2]}.yaml"
else
  puts opt_parser
end
if file_obj
  Vagrant::Util::Subprocess.execute($project.editor.path, $project.editor.options, file_obj)
end
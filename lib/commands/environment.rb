# Specifies environment context for vagrant operations
environment_context = "all";
options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant environment ACTION [OPTIONS]"
  opt.separator  ""
  opt.separator  "Actions"
  opt.separator  "     activate: activate specified environment"
  opt.separator  "     list: lists available environments"
  opt.separator  "     create: create environment folder and skeleton"
  opt.separator  "     remove: remove environment folder"
  opt.separator  ""
  opt.separator  "Options"
  opt.on("-f","--force","Force intended action") do |force|
    options[:force] = true
  end   
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end
opt_parser.parse!
case ARGV[1]
when "activate"
  environment = ARGV[-1]
  # Get the environment path
  environment_path = environment == 'all' ?
  $environment.basedir : "#{$environment.basedir}/#{environment}"
  $logger.info($info.environment.activate % [environment, $environment.context_file])
  if !File.exist?(environment_path)
    $logger.error($errors.environment.path.notfound % environment_path)
    abort
  else
    File.open($environment.context_file,"w") do |file|
      file.write environment
    end
  end
  $logger.info($info.completion.done)
when "create"
  environment_context = ARGV[-1]
  environment_folder = "#{$environment.basedir}/#{environment_context}"
  if File.exist?(environment_folder)
    abort "Abort. Existing environment folder found: #{environment_folder}"
  end
  $environment.skeleton.each do |directory|
    dirobj = "#{environment_folder}/#{directory}"
    puts "Creating #{dirobj}"
    begin 
      FileUtils::mkdir_p dirobj if not File.exist?(dirobj)
    rescue Exception => e
      $logger.error($errors.fso.operations.failure % e)
    end
  end  
when "list"
  Dir.glob("#{$environment.basedir}/*").select {
    |f| 
    puts f if File.directory?(f)
  }
when "remove"
  prompt = VenvCommon::Prompt.new
  environment_context = ARGV[-1]
  environment_folder = "#{$environment.basedir}/#{environment_context}"
  unless options.key?(:force)
    abort("aborted!") if prompt.ask("Are you sure you want to remove and delete #{environment_folder}?", ['y', 'n']) == 'n'
  end
  puts "Removing #{environment_folder}"
  begin 
    FileUtils::rmtree environment_folder if File.exist?(environment_folder)
    puts "Done!"
  rescue Exception => e
    $logger.error($errors.fso.operations.failure % e)
  end
else
  puts opt_parser
end
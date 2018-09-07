# Sets environment context for writing inventory yaml file relevant to specified environment
options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant semaphore SEMAPHORE_NAME ACTION"
  opt.separator  ""
  opt.separator  "Actions"
  opt.separator  "     on: creates a .file under the .vagrant directory with the name of the specified semaphore"
  opt.separator  "     off: deletes the semaphore file"
  opt.separator  ""
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end
opt_parser.parse!
if ARGV.length == 3
  semaphore_file = ".vagrant/.#{ARGV[-2]}"
  case ARGV[-1]
  when "on"

    # Create semaphore file if it does not exist
    if !File.exist?(semaphore_file)
      puts "Creating #{semaphore_file}"
      FileUtils.touch semaphore_file 
    end
  
  when "off"

    # Delete semaphore file if its exists
    if File.exist?(semaphore_file)
      puts "Removing #{semaphore_file}"
      FileUtils.rm_f semaphore_file 
    end    

  else
    puts opt_parser
  end

else 
  puts opt_parser
end
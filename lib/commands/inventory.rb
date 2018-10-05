# Sets environment context for writing inventory yaml file relevant to specified environment
options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant inventory ACTION ENVIRONMENT"
  opt.separator  ""
  opt.separator  "Actions"
  opt.separator  "     create: creates ansible inventory file (inventory.yaml) for specified environment"
  opt.separator  ""
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end
opt_parser.parse!
case ARGV[1]
when "create"
  require File.expand_path("../lib/inventory.rb", __FILE__)
  environment_context = ARGV[-1] != 'create' ? ARGV[-1] : 'all'
  inventory = VenvInventory::Inventory.new
  if [environment_context != 'all', (ARGV.include? 'inventory')].all?
    begin
      inventory.write(environment_context)
    rescue Exception => e
      $logger.error($errors.inventory.file.error % [e, e.backtrace.first.to_s.bold])
    end
    abort
  end      
else
  puts opt_parser
end
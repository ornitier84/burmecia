# Call actions against managed machines
options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vagrant managed ACTION [OPTIONS]"
  opt.separator  ""
  opt.separator  "Actions"
  opt.separator  "     provision: run provisioners against specified managed machine"
  opt.separator  "     shutdown: shut down specified managed machine"
  opt.separator  "     status: print status of managed machines"
  opt.separator  "     up: boot up specified managed machine (via wake-on-lan packet)"
  opt.separator  ""
  opt.separator  "Options"
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end
opt_parser.parse!
case 
when [ "provsion","shutdown","status"].include?(ARGV[1])
  $managed = true
else
  puts opt_parser
end
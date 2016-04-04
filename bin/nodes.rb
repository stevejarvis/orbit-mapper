# Application to run on all nodes to determine connectivity.

require 'net/http'
require 'optparse'
require 'json'

PORT = 4567

# Parse and set options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"
  opts.on('-m address', '--master-address=address', 'Address of controller') do |address|
    options[:master_address] = address
  end
  opts.on('-d time', '--delay=time', 'Delay between pings') do |time|
    options[:delay] = Integer(time)
  end
end.parse!

# Helper to determine if the controller's web server is available yet.
def serverup?(ip, port)
  http = Net::HTTP.start(ip, port, {open_timeout:3, read_timeout:3})
  response = http.send_request('GET', '/')
  JSON.parse(response.body)
rescue Timeout::Error, SocketError, Errno::ECONNREFUSED
  nil
end

# Parse the raw ping output to a hash with useful information.
def parseping(output)
  res = Hash.new
  begin
    res[:success] = 100 - Integer(output.match(/([[:digit:]]+)% packet loss/m)[1])
    res[:rtt] = Float(output.match(/= [[:digit:]\.]+\/([[:digit:]\.]+)\//m)[1])
  rescue NoMethodError, TypeError
    # Do nothing, just fall through and return the empty hash.
  end
  res
end

# Ping a single node and return the parsed output as a hash.
def pingnode(address, interface=nil)
  out = interface ? `ping -I #{interface} -c 5 #{address}` : `ping -c 5 #{address}`
  if $? != 0
    # Ping command failed, return empty hash.
    puts "Failed to ping #{address} on #{interface}"
    Hash.new
  else
    res = parseping(out)
    res[:address] = address
    res
  end
end

# Upload the current network view from this perspective to the controller.
# Map is actually a list of hashes with connectivity metrics (addresses, rtt,
# drop rate).
def report_connectivity(controller, connectivity_map)
  me = `hostname`.chomp
  req = Net::HTTP::Post.new("/#{me}", initheader = {'Content-Type'=>'application/json'})
  req.body = connectivity_map.to_json
  response = Net::HTTP.start(controller, PORT) do |http|
    http.request(req)
  end
  response.code == '200'
end

def run!(controller, delay, interface=nil)
  consecutive_fails = 0
  while consecutive_fails < 5 do # If we can't reach master, quit after a while.
    nodelist = serverup?(controller, PORT)
    if nodelist
      consecutive_fails = 0
      connectivity = Array.new
      nodelist.each do |node|
        connectivity << pingnode(node['address'], interface)
      end
      report_connectivity(controller, connectivity)
    else
      consecutive_fails += 1
    end
    sleep(delay)
  end
end

if __FILE__ == $0
  run!(options[:master_address], options[:delay])
end

# Application to run on all nodes to determine connectivity.

require 'net/http'
require 'optparse'
require 'json'

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
  opts.on('-i int', '--interface=int', 'Interface to use for pings') do |int|
    options[:interface] = int
  end
  opts.on('-p port', '--bind-port=port', 'Port to use to contact controller') do |port|
    options[:bind_port] = Integer(port)
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
def report_connectivity(controller, port, connectivity_map)
  me = `hostname`.chomp
  req = Net::HTTP::Post.new("/#{me}", initheader = {'Content-Type'=>'application/json'})
  req.body = connectivity_map.to_json
  response = Net::HTTP.start(controller, port) do |http|
    http.request(req)
  end
  response.code == '200'
end

def run!(controller, delay, port, interface=nil)
  consecutive_fails = 0
  while consecutive_fails < 5 do # If we can't reach master, quit after a while.
    nodelist = serverup?(controller, port)
    if nodelist
      consecutive_fails = 0
      connectivity = Array.new
      nodelist.each do |node|
        ping_results = pingnode(node['address'], interface)
        # Keep the hostname, since it usually looks better in the final map.
        ping_results[:host] = node['host']
        connectivity << ping_results
      end
      report_connectivity(controller, port, connectivity)
    else
      consecutive_fails += 1
    end
    sleep(delay)
  end
end

if __FILE__ == $0
  run!(options[:master_address], options[:delay], options[:bind_port], options[:interface])
end

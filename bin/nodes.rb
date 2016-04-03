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
  response = http.head('/')
  response.code == '200'
rescue Timeout::Error, SocketError, Errno::ECONNREFUSED
  false
end

# Parse the raw ping output to a hash with useful information.
def parseping(output)
  res = Hash.new
  begin
    res['success'] = 100 - Integer(output.match(/([[:digit:]]+)% packet loss/m)[1])
    res['rtt'] = Float(output.match(/= [[:digit:]\.]+\/([[:digit:]\.]+)\//m)[1])
  rescue NoMethodError, TypeError
    return nil
  end
  res
end

# TODO ping all other nodes in the network, figure out who is available.
# Maybe continue forever, until the server is unreachable for 'x' consecutive
# seconds? Get a connectivity raiting, out of 3 pings or so, maybe RTT and loss.
# For now just placeholder logic.

def run!
  consecutive_fails = 0
  while consecutive_fails < 5 do # If we can't reach master, quit.
  if serverup?(options[:master_address], PORT)
    consecutive_fails = 0
        http = Net::HTTP.new(options[:master_address], PORT)

        response = http.send_request('PUT', '/me?visible=192.168.0.1,192.168.0.30', 'body')

        response = http.send_request('GET', '/me')
    else
        consecutive_fails += 1
    end
    sleep(options[:delay])
    end
end

if __FILE__ == $0
  run!
end

# Application to run on all nodes to determine connectivity.

require 'net/http'
require 'optparse'

PORT = 4567

# Parse and set options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"
  opts.on('-m address', '--master-address=address', 'Master') do |address|
    options[:master_address] = address
  end
end.parse!

# Helper to determine if the server is available yet.
def serverup?(ip, port)
  http = Net::HTTP.start(ip, port, {open_timeout:3, read_timeout:3})
  response = http.head('/')
  response.code == '200'
rescue Timeout::Error, SocketError, Errno::ECONNREFUSED
  false
end

# TODO ping all other nodes in the network, figure out who is available.
# Maybe continue forever, until the server is unreachable for 'x' consecutive
# seconds?

consecutive_fails = 0
while consecutive_fails < 5 do
  if serverup?(options[:master_address], PORT)
    consecutive_fails = 0
    http = Net::HTTP.new(options[:master_address], PORT)

    response = http.send_request('PUT', '/me?visible=192.168.0.1', 'body')

    response = http.send_request('GET', '/me')
  else
    consecutive_fails += 1
  end
  sleep(1)
end

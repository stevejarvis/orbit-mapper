# Application to run on all nodes to determine connectivity.

require 'net/http'

port = 4567
host = '192.168.0.27'

# Helper to determine if the server is available yet.
def serverup?(ip, port)
  http = Net::HTTP.start(ip, port, {open_timeout:3, read_timeout:3})
  response = http.head('/')
  puts response.code
  response.code == '200'
rescue Timeout::Error, SocketError, Errno::ECONNREFUSED
  false
end

# TODO ping all other nodes in the network, figure out who is available.
# Maybe continue forever, until the server is unreachable for 'x' consecutive
# seconds?

consecutive_fails = 0
while consecutive_fails < 5 do
  if serverup?(host, port)
    consecutive_fails = 0
    puts "Reporting data to server process"
    http = Net::HTTP.new(host, port)
    response = http.send_request('PUT', '/me?visible=192.168.0.1', 'body')
    puts response.code

    puts "Now requesting that info back"
    response = http.send_request('GET', '/me')
    puts "#{response.code} --> #{response.body}"
  else
    consecutive_fails += 1
  end
  sleep(1)
end

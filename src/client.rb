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

# Wait for server to come up.
until serverup?(host, port)
  puts "Waiting to rock until REST API is available"
  sleep(1)
end

puts "Reporting data to server process"
http = Net::HTTP.new(host, port)
response = http.send_request('PUT', '/me?visible=192.168.0.1', 'body')
puts response.code

puts "Now requesting that info back"
response = http.send_request('GET', '/me')
puts "#{response.code} --> #{response.body}"

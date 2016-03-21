require 'net/http'

port = 4567
host = '127.0.0.1'

puts "Reporting data to server process..."
http = Net::HTTP.new(host, port)
response = http.send_request('PUT', '/me?visible=192.168.0.1', 'body')
puts response.code

puts "Now requesting that info back..."
response = http.send_request('GET', '/me')
puts "#{response.code} --> #{response.body}"

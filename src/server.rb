# Application to execute on the console node. Offers a RESTful interface for
# modifying the network map and finds the desired topology.
#
# Run from root of application dir.

require 'sinatra'
require 'net/ssh'
require 'net/scp'
require 'net/http'

set :bind, '0.0.0.0'

# These ssh keys must be added to the agent, net-ssh does not have its own
# implementation of an agent.
nodes = [{'ip':'192.168.0.101', 'user':'pi', 'key':'/home/sjarvis/.ssh/id_rsa'}]

# Deploy and execute the client to gather information on the
# nodes.
Thread.new {
  nodes.each do |node|
    dst_path = '/tmp/'
    puts "Deploying to #{node[:ip]}:#{dst_path}"
    Net::SCP.upload!(node[:ip], node[:user],
                     "#{Dir.pwd}/src/client.rb", dst_path,
                     :ssh => {:keys => [node[:key]]})
    Net::SSH.start(node[:ip], node[:user], :keys => [node[:key]]) do |ssh|
      puts ssh.exec! "ruby #{dst_path}/client.rb"
    end
  end
}

# House the set of information regarding connectivity.
data = {}

# Simple GET to ping root URL.
get '/' do
  "Hola"
end

# GET requests a particular topology, which we compute based on the current
# known network graph.
get '/:arg' do
  puts "Getting #{params['arg']}"
  data["#{params['arg']}"]
end

# PUT saves the supplied mapping information. The sender should include
# a list of all nodes visible to it, stored by IP. Or ID? I don't know.
put '/:sender' do
  puts "Putting for #{params['sender']} = #{:visible}"
  data["#{params['sender']}"] = params[:visible]
  "Ok"
end

# Application to execute on the console node. Offers a RESTful interface for
# modifying the network map and finds the desired topology.
#
# Run from root of application dir.

require 'sinatra/base'
require 'net/ssh'
require 'net/scp'
require 'net/http'
require 'optparse'
require 'json'

# Parse and set options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"
  opts.on('-m address', '--master-address=address', 'Master') do |address|
    options[:master_address] = address
  end
  opts.on('-n nodelist', '--node-list=nodelist', 'Node List') do |nodelist|
    options[:nodelist] = nodelist
  end
  opts.on('-d time', '--delay=time', 'Delay') do |time|
    options[:delay] = Integer(time)
  end
end.parse!

# Store all connectivity data.
# TODO will probably need to make a threadsafe hash, but don't konw much about concurrency in Ruby yet.
$connection_map = Hash.new

def loadconfig(configfile)
  JSON.parse(File.read(configfile))
end

# Deploy and execute the client to gather information on the nodes.
def deploy(configfile, address, delay)
  # The ssh keys must be added to ssh-agent, net-ssh does not have its own
  # implementation of an agent.
  h = loadconfig(configfile)
  h.each do |node|
    dst_path = '/tmp/'
    puts "Deploying to #{node['address']}:#{dst_path}"
    Net::SCP.upload!(node['address'], node['user'],
                     "#{Dir.pwd}/src/nodes.rb", dst_path,
                     :ssh => {:keys => [node['key']]})
    Net::SSH.start(node['address'], node['user'], :keys => [node['key']]) do |ssh|
      ssh.exec "ruby #{dst_path}/nodes.rb -m #{address} -d #{delay} &"
    end
  end
end

dt = Thread.new do
  deploy(options[:nodelist], options[:master_address], options[:delay])
end

class Restful < Sinatra::Base
  # Sinatra REST setup.
  set :bind, '0.0.0.0'
  set :logging, true
  set :server, :puma
  enable :traps

  set :conn_map, $connection_map

  # Simple GET to ping root URL.
  get '/' do
    getnodes
  end

  # GET requests a particular topology, which we compute based on the current
  # known network graph.
  get '/:context_node' do
    # Return what the context node has reported as visible.
    settings.conn_map[params['context_node']]
  end

  # PUT saves the supplied mapping information. The sender should include
  # a list of all nodes visible to it, stored by IP. Or ID? I don't know.
  put '/:sender' do
    # Access the application scope with help from settings, otherwise
    # we're in the request scope.
    settings.conn_map[params['sender']] = params['visible']
    "Thank you"
  end

  # Enumerate only the node addresses, return JSON string.
  def getnodes()
    res = []
    h = JSON.parse(File.read(settings.configfile))
    h.each do |node|
      res.push({'address'=>node['address']})
    end
    res.to_json
  end
end

puts "Using nodelist #{options[:nodelist]}"
Restful.set :configfile, options[:nodelist]
Restful.run!

dt.join

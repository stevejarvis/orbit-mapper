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
require 'thread'
require 'thwait'

require_relative '../lib/utils'

# Parse and set options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"
  opts.on('-m address', '--master-address=address', 'Address of controlling node') do |address|
    options[:master_address] = String(address)
  end
  opts.on('-n nodelist', '--node-list=nodelist', 'List of nodes to map') do |nodelist|
    options[:nodelist] = String(nodelist)
  end
  opts.on('-d time', '--delay=time', 'Delay between pings and updates') do |time|
    options[:delay] = Integer(time)
  end
  opts.on('-o fname', '--outfile=fname', 'File to output GEXF connection data') do |fname|
    options[:outfile] = String(fname)
  end
end.parse!

@running = true
@threads = Array.new

# Store all connectivity data.
# TODO will probably need to make a threadsafe hash, but don't know much about concurrency in Ruby yet.
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
    puts "Deploying nodes.rb to #{node['address']}:#{dst_path}"
    @threads << Thread.new do
      Net::SSH.start(node['address'], node['user'], :keys => [node['key']]) do |ssh|
        # ! is blocking here
        ssh.scp.upload! "#{Dir.pwd}/bin/nodes.rb", dst_path
        # exec (no !) does not block
        # NOTE *should* not block. It seems the session (incorrectly) refuses
        # to close without these bash trickeries to close stdin/stdout/stderr.
        ssh.exec "sh -c 'ruby #{dst_path}/nodes.rb -m #{address} -d #{delay} </dev/null >/dev/null 2>&1 &'"
      end
    end
  end
end

class Restful < Sinatra::Base
  # Sinatra REST setup.
  set :bind, '0.0.0.0'
  set :logging, true
  disable :traps

  set :conn_map, $connection_map

  # Simple GET to ping root URL.
  get '/' do
    getnodesjson
  end

  # GET requests a particular topology, which we compute based on the current
  # known network graph.
  get '/:context_node' do
    # Return what the context node has reported as visible.
    settings.conn_map[params['context_node']]
  end

  # POST saves the supplied mapping information. The sender should include
  # JSON information on connectivity to all nodes.
  post '/:sender' do
    # Access the application scope with help from settings, otherwise
    # we're in the request scope.
    settings.conn_map[params['sender']] = JSON.parse(request.body.read)
    "Thanks"
  end

  # Enumerate only the node addresses, return JSON string.
  def getnodesjson()
    res = []
    h = JSON.parse(File.read(settings.configfile))
    h.each do |node|
      res.push({'address'=>node['address'], 'int'=>node['int']})
    end
    res.to_json
  end
end

puts "Using nodelist #{options[:nodelist]}"
Restful.set :configfile, options[:nodelist]
# Run the server in another thread.
@threads << Thread.new do
  Restful.run!
end

puts "Deploying and staring node application on all nodes"
deploy(options[:nodelist], options[:master_address], options[:delay])

# catch interrupt and stop
trap 'SIGINT' do
  puts "Exiting..."
  @running = false
  Restful.quit!
  ThreadsWait.all_waits(*@threads)
end

# Now for the duration of the application, periodically write the current
# connectivity data to a file.
while @running
  out = dump_gexf($connection_map).target!
  File.open("#{options[:outfile]}.gexf", 'w') { |file| file.write(out) }
  puts "Updated #{options[:outfile]}.gexf"
  sleep(options[:delay])
end

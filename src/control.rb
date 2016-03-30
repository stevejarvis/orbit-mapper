# Application to execute on the console node. Offers a RESTful interface for
# modifying the network map and finds the desired topology.
#
# Run from root of application dir.

require 'sinatra/base'
require 'net/ssh'
require 'net/scp'
require 'net/http'
require 'curses'
require 'optparse'

include Curses

# Parse and set options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"
  opts.on('-c', '--curses', 'Curses') { |v| options[:curses] = v }
  opts.on('-m address', '--master-address=address', 'Master') do |address|
    options[:master_address] = address
  end
end.parse!

# Store all connectivity data.
# TODO will probably need to make a threadsafe hash, but don't konw much about concurrency in Ruby yet.
$connection_map = Hash.new

# Sinatra REST setup.
st = Thread.new do
  class Restful < Sinatra::Base
    set :bind, '0.0.0.0'
    set :logging, nil
    set :server, :puma
    disable :traps

    set :conn_map, $connection_map

    # Simple GET to ping root URL.
    get '/' do
      "Hola"
    end

    # GET requests a particular topology, which we compute based on the current
    # known network graph.
    get '/:context_node' do
      # TODO Compute a topology here. For now, just return what the context node
      # has reported as visible.
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
  end

  Restful.run!
end

# Deploy and execute the client to gather information on the nodes.
dt = Thread.new do
  # These ssh keys must be added to ssh-agent, net-ssh does not have its own
  # implementation of an agent.
  nodes = [{'ip'=>'192.168.0.101', 'user'=>'pi', 'key'=>"#{ENV['HOME']}/.ssh/id_rsa"}]

  nodes.each do |node|
    dst_path = '/tmp/'
    puts "Deploying to #{node['ip']}:#{dst_path}"
    Net::SCP.upload!(node['ip'], node['user'],
                     "#{Dir.pwd}/src/nodes.rb", dst_path,
                     :ssh => {:keys => [node['key']]})
    Net::SSH.start(node['ip'], node['user'], :keys => [node['key']]) do |ssh|
      ssh.exec "ruby #{dst_path}/nodes.rb -m #{options[:master_address]} &"
    end
  end
end

# Continuously draw and refresh the curses screen. Needs a context node, taken
# by click.
def drawmap(win, context_x, context_y)
  win.box(?|, ?-)
  win.setpos(2,3)
  # TODO draw connectivity from the current context
  win.addstr("#{$connection_map['me']}")
  win.refresh
end

# Start the curses visual
def startcurses()
  init_screen
  begin
    start_color
    crmode
    win = Window.new( 20, 40, (Curses.lines - 20) / 2, (Curses.cols - 40) / 2 )
    while true do
      drawmap(win, 1, 1)
      sleep(2)
    end
  ensure
    close_screen
    win.close
  end
end

if options[:curses]
  sleep(2) # <-- hacky, to keep stdout off curses
  startcurses
end

st.join
dt.join

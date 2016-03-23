# Application to execute on the console node. Offers a RESTful interface for
# modifying the network map and finds the desired topology.
#
# Run from root of application dir.

require 'sinatra/base'
require 'net/ssh'
require 'net/scp'
require 'net/http'
require 'curses'

include Curses

# Sinatra REST setup.
st = Thread.new do
  class MServer < Sinatra::Base
    set :bind, '0.0.0.0'
    set :server, 'thin'
    set :logging, nil
    set :trap, false

    # Simple GET to ping root URL.
    get '/' do
      return "Hola"
    end

    # GET requests a particular topology, which we compute based on the current
    # known network graph.
    get '/:arg' do
      # TODO Compute a topology here. Figure out how to get a variable in
      # scope here.
    end

    # PUT saves the supplied mapping information. The sender should include
    # a list of all nodes visible to it, stored by IP. Or ID? I don't know.
    put '/:sender' do
      "Ok"
    end

  end

  MServer.run!
end

# Deploy and execute the client to gather information on the nodes.
dt = Thread.new do
  # These ssh keys must be added to ssh-agent, net-ssh does not have its own
  # implementation of an agent.
  nodes = [{'ip':'192.168.0.101', 'user':'pi', 'key':"#{ENV['HOME']}/.ssh/id_rsa"}]

  nodes.each do |node|
    dst_path = '/tmp/'
    puts "Deploying to #{node[:ip]}:#{dst_path}"
    Net::SCP.upload!(node[:ip], node[:user],
                     "#{Dir.pwd}/src/client.rb", dst_path,
                     :ssh => {:keys => [node[:key]]})
    Net::SSH.start(node[:ip], node[:user], :keys => [node[:key]]) do |ssh|
      ssh.exec "ruby #{dst_path}/client.rb &"
    end
  end
end

# Continuously draw and refresh the curses screen. Needs a context node, taken
# by click.
def drawmap(win, context_x, context_y)
  win.box(?|, ?-)
  win.setpos(2,3)
  win.addstr(`date`)
  win.refresh
end

sleep(2) # <-- hacky, to keep stdout off curses
# Start curses
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

st.join
# Won't actually join until all remote processes stop.
dt.join

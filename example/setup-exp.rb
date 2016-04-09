defProperty('duration', 60*30, "Duration of the experiment")

rt = defTopology("nodes", 'node1-1.grid.orbit-lab.org,node1-2.grid.orbit-lab.org,node1-3.grid.orbit-lab.org,node1-4.grid.orbit-lab.org,node2-1.grid.orbit-lab.org,node2-2.grid.orbit-lab.org,node3-1.grid.orbit-lab.org,node3-2.grid.orbit-lab.org,node3-3.grid.orbit-lab.org,node4-1.grid.orbit-lab.org,node4-3.grid.orbit-lab.org') do |t|
  info "#{t.size} nodes in experiment."
end

defGroup('Nodes', "nodes") do |node|
  # Add application and set properties for it here.
end

allGroups.net.w0 do |interface|
  interface.mode = "adhoc"
  interface.type = 'g'
  interface.channel = "6"
  interface.ip = "192.168.0.%index%"
  interface.essid = "hello"
end

onEvent(:ALL_UP_AND_INSTALLED) do |event|
  info "All interfaces are set up."
  # Start the group(s) applications here.
  wait property.duration
  info "Wrapping up now."
  Experiment.done
end

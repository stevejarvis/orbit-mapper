# The syntax of this file is documented at [0] and [1].
#
# [0] http://doc.mytestbed.net/doc/omf/OmfEc/Backward/AppDefinition.html
# [1] http://omf.mytestbed.net

name = "Mapper Experiment"
baseTopo = Topology['system:topo:imaged']
defProperty('duration', 60, "Duration of the experiment")

defApplication('map_experiment', 'map_experiment') do |app|

  app.version(1, 0, 0)
  app.shortDescription = 'Experiment to Demonstrate Using Mapping API'
  app.description = %{
This is an experiment to demonstrate how an existing experiment can use the
mapping API provided by Orbit Mapper. There are no additional measurements
needed, those taken here are only for demonstration.
}
  app.path = "/experiment/map_experiment"
  # Make this tarball actually exist: tar -cf experiment.tar map_exeriment
  app.appPackage = "experiment.tar"

  # Declare command-line arguments; generate Popt parser with
  #  oml2-scaffold --opts map_experiment.rb
  app.defProperty('controller', 'Address of the controlling machine', '-c',
        :type => :string, :mnemonic => 'c')
  app.defProperty('delay', 'Delay between consecutive API queries', '-d',
        :type => :double, :unit => 'seconds', :mnemonic => 'd', :default => '5.0')

  # Declare measurement points; generate OML injection helpers with
  #  oml2-scaffold --oml map_experiment.rb
  app.defMeasurement("query") do |mp|
    mp.defMetric('self', :int32)
    mp.defMetric('topology', :vector_int32)
  end
end

defTopology('nodes') do |t|
  t.addNode(baseTopo.getNodeByIndex(0))
  t.addNode(baseTopo.getNodeByIndex(1))
end

defGroup('ExperimentNodes', 'nodes') do |node|
  node.addApplication("map_experiment") do |app|
    app.measure('query', :samples => 1)
  end
  node.net.w1.mode = "adhoc"
  node.net.w1.type = 'g'
  node.net.w1.channel = "6"
  node.net.w1.essid = "helloworld"
  node.net.w1.ip = "192.168.0.2"
end

onEvent(:ALL_UP_AND_INSTALLED) do |event|
  info "Running experiment..."
  wait 10
  allGroups.startApplications
  info "All applications are started..."
  wait property.duration
  allGroups.stopApplications
  info "All my Applications are stopped."
  Experiment.done
end

# Local Variables:
# mode:ruby
# End:
# vim: ft=ruby:sw=2

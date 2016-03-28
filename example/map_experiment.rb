# This file is based on an automatically generated version by
# oml2-scaffold 2.12.0pre.147-8fe8-dirty
# The syntax of this file is documented at [0].
#
# [0] http://doc.mytestbed.net/doc/omf/OmfEc/Backward/AppDefinition.html

defApplication('sjarvis:app:map_experiment', 'map_experiment') do |app|

  app.version(1, 0, 0)
  app.shortDescription = 'Experiment to Demonstrate Using Mapping API'
  app.description = %{
This is an experiment to demonstrate how an existing experiment can use the
mapping API provided by Orbit Mapper. There are no additional measurements
needed, those taken here are only for demonstration.
}
  app.path = "/usr/local/bin/map_experiment"

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

# Local Variables:
# mode:ruby
# End:
# vim: ft=ruby:sw=2

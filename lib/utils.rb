require 'builder'

# Output the network data to a file in the GEXF format. Input is a map of context
# nodes to lists of hashes of information about each of their peers.
def dump_gexf(connectivity_map)
  xml = Builder::XmlMarkup.new(:indent => 2)
  xml.instruct! :xml, :version => '1.0', :encoding => 'UTF-8'

  xml.gexf( :xmlns => "http://www.gexf.net/1.2draft", :version => "1.2" ) do

    xml.meta( :lastmodifieddate => Time.now.strftime("%Y-%d-%m") ) do |m|
      m.creator( "Orbit Mapper" ); m.description( "Current state of known network connectedness." )
    end

    xml.graph( :mode => "static", :defaultedgetype => "directed" ) do

      xml.attributes( :class => "edge", :mode => "static" ) do
        xml.attribute( :id => 0, :title => "success", :type => "float" )
        xml.attribute( :id => 1, :title => "rtt", :type => "float" )
      end

      # Add nodes section
      xml.nodes do
        connectivity_map.each do |key, vals|
          xml.node( :id => key, :label => key )
        end
      end

      # Create all the edges
      xml.edges do
        count = 0
        connectivity_map.each do |key, val|
          # Also edges element
          val.each do |info|
            if info['address'].to_s != ''
              xml.edge( :id => count, :source => key, :target => info['host'] ) do
                xml.attvalues do
                  xml.attvalue( :for => 0, :value => info['success'] )
                  xml.attvalue( :for => 1, :value => info['rtt'] )
                end
              end
              count += 1
            end
          end
        end
      end

    end # graph
  end # gexf

  xml
end

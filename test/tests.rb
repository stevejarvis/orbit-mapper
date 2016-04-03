require 'builder'
require 'test/unit'
require_relative '../lib/utils.rb'
require_relative '../bin/nodes.rb'

class ControlTests < Test::Unit::TestCase

  def test_gexf
    conn_map = { 'node0'=>['node1','node2'], 'node1'=>['node0'], 'node2'=>['node0','node1'] }
    # Excuse the indentation
    assert_equal(dump_gexf(conn_map).target!,
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\">
  <meta lastmodifieddate=\"2016-02-04\">
    <creator>Orbit Mapper</creator>
    <description>Current state of known network connectedness.</description>
  </meta>
  <graph mode=\"static\" defaultedgetype=\"directed\">
    <nodes>
      <node id=\"node0\" label=\"node0\"/>
      <node id=\"node1\" label=\"node1\"/>
      <node id=\"node2\" label=\"node2\"/>
    </nodes>
    <edges>
      <edge id=\"0\" source=\"node0\" target=\"node1\"/>
      <edge id=\"1\" source=\"node0\" target=\"node2\"/>
      <edge id=\"2\" source=\"node1\" target=\"node0\"/>
      <edge id=\"3\" source=\"node2\" target=\"node0\"/>
      <edge id=\"4\" source=\"node2\" target=\"node1\"/>
    </edges>
  </graph>
</gexf>\n")
  end

  def test_pingparse
    input =
      "PING localhost.localdomain (127.0.0.1) 56(84) bytes of data.
       64 bytes from localhost.localdomain (127.0.0.1): icmp_seq=1 ttl=64 time=0.035 ms
       64 bytes from localhost.localdomain (127.0.0.1): icmp_seq=2 ttl=64 time=0.052 ms
       64 bytes from localhost.localdomain (127.0.0.1): icmp_seq=3 ttl=64 time=0.037 ms
       64 bytes from localhost.localdomain (127.0.0.1): icmp_seq=4 ttl=64 time=0.036 ms
       64 bytes from localhost.localdomain (127.0.0.1): icmp_seq=5 ttl=64 time=0.036 ms

       --- localhost.localdomain ping statistics ---
       5 packets transmitted, 5 received, 0% packet loss, time 3999ms
       rtt min/avg/max/mdev = 0.035/0.039/0.052/0.007 ms
      "
    assert_equal({'success'=>100, 'rtt'=>0.039},
                 parseping(input))
  end

end

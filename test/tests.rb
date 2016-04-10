require 'builder'
require 'test/unit'
require_relative '../lib/utils.rb'
require_relative '../bin/nodes.rb'

class ControlTests < Test::Unit::TestCase

  def test_gexf
    conn_map = { 'node0'=>[ { 'host'=>'node1', 'address'=>'192.168.0.2', 'success'=>97, 'rtt'=>0.57 }, { 'host'=>'node2', 'address'=>'192.168.0.3', 'success'=>94, 'rtt'=>0.51 } ],
                 'node1'=>[ { 'host'=>'node0', 'address'=>'192.168.0.1', 'success'=>99, 'rtt'=>0.47 } ],
                 'node2'=>[ { 'host'=>'node0', 'address'=>'192.168.0.1', 'success'=>95, 'rtt'=>0.56 }, { 'host'=>'node1', 'address'=>'192.168.0.2', 'success'=>99, 'rtt'=>0.21 } ] }
    # Excuse the indentation
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\">\n  <meta lastmodifieddate=\"#{Time.now.strftime("%Y-%d-%m")}\">\n    <creator>Orbit Mapper</creator>\n    <description>Current state of known network connectedness.</description>\n  </meta>\n  <graph mode=\"static\" defaultedgetype=\"directed\">\n    <attributes class=\"edge\" mode=\"static\">\n      <attribute id=\"0\" title=\"success\" type=\"float\"/>\n      <attribute id=\"1\" title=\"rtt\" type=\"float\"/>\n    </attributes>\n    <nodes>\n      <node id=\"node0\" label=\"node0\"/>\n      <node id=\"node1\" label=\"node1\"/>\n      <node id=\"node2\" label=\"node2\"/>\n    </nodes>\n    <edges>\n      <edge id=\"0\" source=\"node0\" target=\"node1\">\n        <attvalues>\n          <attvalue for=\"0\" value=\"97\"/>\n          <attvalue for=\"1\" value=\"0.57\"/>\n        </attvalues>\n      </edge>\n      <edge id=\"1\" source=\"node0\" target=\"node2\">\n        <attvalues>\n          <attvalue for=\"0\" value=\"94\"/>\n          <attvalue for=\"1\" value=\"0.51\"/>\n        </attvalues>\n      </edge>\n      <edge id=\"2\" source=\"node1\" target=\"node0\">\n        <attvalues>\n          <attvalue for=\"0\" value=\"99\"/>\n          <attvalue for=\"1\" value=\"0.47\"/>\n        </attvalues>\n      </edge>\n      <edge id=\"3\" source=\"node2\" target=\"node0\">\n        <attvalues>\n          <attvalue for=\"0\" value=\"95\"/>\n          <attvalue for=\"1\" value=\"0.56\"/>\n        </attvalues>\n      </edge>\n      <edge id=\"4\" source=\"node2\" target=\"node1\">\n        <attvalues>\n          <attvalue for=\"0\" value=\"99\"/>\n          <attvalue for=\"1\" value=\"0.21\"/>\n        </attvalues>\n      </edge>\n    </edges>\n  </graph>\n</gexf>\n",
                 dump_gexf(conn_map).target!)
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
    assert_equal({:success=>100, :rtt=>0.039},
                 parseping(input))
  end

  def test_pingnode
    res = pingnode('127.0.0.1') # No interface
    assert(res.size > 0)
    assert_equal('127.0.0.1', res[:address])
  end

end

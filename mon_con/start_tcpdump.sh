#/bin/bash
TIMESTAMP=`date`

tcpdump -i cni0 not host 10.96.0.1 and host 10.40.3.212 or host 10.40.3.216 and not host 10.96.0.1 -w node1_tcp_mon_fail_node2.dump

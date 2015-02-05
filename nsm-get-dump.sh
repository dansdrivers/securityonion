#!/bin/bash

#2014-12-16 16:45:20 64.4.45.42 192.168.1.210 443 56722 6
DAY=$1
TIME=$2
FILE=$(find /nsm/sensor_data/`hostname`-eth1/dailylogs/$DAY/ -newermt "$DAY $TIME" -type f | head -n 1)

SIP=$3
DIP=$4
SPRT=$5
DPRT=$6
PROT=$7

echo
echo "/usr/sbin/tcpdump"
echo "  -r $FILE"
echo "  -w /tmp/nsm-dump.raw"
echo "  (ip and host $SIP and host $DIP and port $SPRT and port $DPRT and proto $PROT)"
echo "    or"
echo "  (vlan and host $SIP and host $DIP and port $SPRT and port $DPRT and proto $PROT)"
echo
/usr/sbin/tcpdump -r $FILE -w /tmp/nsm-dump.raw \(ip and host $SIP and host $DIP and port $SPRT and port $DPRT and proto $PROT\) or \(vlan and host $SIP and host $DIP and port $SPRT and port $DPRT and proto $PROT\)

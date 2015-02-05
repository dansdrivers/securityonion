#!/bin/bash
if (( EUID != 0 )); then
    echo "You must be root to do this." 1>&2
    exit 1
fi
tar -cvf back_config_files.tar \
/etc/cron.d/elsa \
/etc/elsa_node.conf /etc/elsa_web.conf \
/etc/network/interfaces \
/etc/nsm/pulledpork/disablesid.conf \
/etc/nsm/rules/local.rules \
/etc/nsm/`hostname`-eth1/sensor.conf \
/etc/nsm/securityonion/autocat.conf \
/etc/nsm/securityonion.conf \
/opt/bro/etc/node.cfg \
/opt/elsa/node/conf/elsa.conf \
/var/ossec/bin/ossec-control


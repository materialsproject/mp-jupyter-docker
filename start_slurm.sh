#!/bin/bash

if [ ! -e /usr/local/etc/slurm.conf ]; then
  name=`hostname -s`
  /root/SlurmDocker/scripts/slurm-config.sh $name $name CPUs=1
fi

if [ ! -f /tmp/munge.key ]; then
  PASSWORD=${1:-"Setec Astronomy"}
  echo -n $PASSWORD | sha512sum | cut -d' ' -f1 > /tmp/munge.key
  chown munge:munge /tmp/munge.key
  chmod go-rwx /tmp/munge.key
fi

LD_LIBRARY_PATH=/usr/local/lib /usr/local/sbin/munged -f --syslog --key-file=/tmp/munge.key --pid-file=/tmp/munged.pid --socket=/tmp/munge.socket.2
/usr/local/sbin/slurmctld && /usr/local/sbin/slurmd

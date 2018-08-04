#!/bin/bash
name=`hostname -s`
/root/SlurmDocker/scripts/slurm-config.sh $name $name CPUs=1 && \
/root/SlurmDocker/scripts/munged.sh && \
/usr/local/sbin/slurmctld && /usr/local/sbin/slurmd

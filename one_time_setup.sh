#!/bin/bash

if [ ! -e /home/jovyan/.ssh/id_rsa ]; then
  ssh-keygen -f /home/jovyan/.ssh/id_rsa -t rsa -N '' -b 4097
  eval `ssh-agent -s` && ssh-add /home/jovyan/.ssh/id_rsa
  pmg config --add PMG_MAPI_KEY $PMG_MAPI_KEY
  sleep 5 # waiting for mongod to start
  mongorestore --archive=/home/jovyan/example_tasks.tar.gz && rm -v /home/jovyan/example_tasks.tar.gz
  mongorestore -d jcap -c tasks --gzip /home/jovyan/tasks_jcap.bson.gz && rm -v /home/jovyan/tasks_jcap.bson.gz
  mongorestore -d structure_tagging -c mp_structures --gzip /home/jovyan/mp_structures.bson.gz && rm -v /home/jovyan/mp_structures.bson.gz
  mongorestore -d structure_tagging -c amcsd_structures --gzip /home/jovyan/amcsd_structures.bson.gz && rm -v /home/jovyan/amcsd_structures.bson.gz
fi

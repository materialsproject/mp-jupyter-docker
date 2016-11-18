mongod --fork --logpath /data/db/mongod.log
source activate python2
mpcontribs 2>&1 &
source deactivate python2
sleep 5
exec sh /srv/singleuser/singleuser.sh --NotebookApp.allow_origin='*'

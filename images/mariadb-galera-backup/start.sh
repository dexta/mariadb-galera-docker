#!/bin/bash

echo
echo "MariaDB Galera Backup Agent"
echo "---------------------------"
echo "mode: $1"
echo

if [ -z $INC_BACKUP_INTERVAL ]; then
  INC_BACKUP_INTERVAL=15
fi


case "$1" in
	sleep)
		echo "Sleeping forever..."
		sleep infinity
		exit
		;;
	bash)
		echo "Executing ad-hoc bash command: $@..."
		shift 1
		/bin/bash "$@"
		exit
		;;
	agent)
		echo "Starting automated backup agent..."
    while [ 1 ]
    do
	    /usr/local/bin/percona-backup.sh
			sleep $INC_BACKUP_INTERVAL
    done
		;;
	backup)
		echo "Starting ad-hoc backup..."
		/usr/local/bin/percona-backup.sh
		;;
	stage)
		echo "Starting ad-hoc restore to staging validation db..."
    /usr/local/bin/percona-stage.sh
		;;
	restore)
		echo "Starting ad-hoc restore to galera cluster master (all nodes must be down)..."
    /usr/local/bin/percona-restore.sh
		;;
	*)
    echo "invalid argument!"
		echo "usage: sleep|bash|agent|backup|stage|restore"
    sleep 10s
		exit 1
esac




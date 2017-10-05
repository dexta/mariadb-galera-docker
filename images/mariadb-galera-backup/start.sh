#!/bin/bash

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
	cron)
		echo "Starting cron scheduled backup tasks..."
    cron
    while [ 1 ]
    do
			if [ -f /var/log/cron/cron.log ]; then
	      cat /var/log/cron/cron.log >> /var/log/cron/cron_history.log
				cat /var/log/cron/cron.log
				rm /var/log/cron/cron.log
				touch /var/log/cron/cron.log
			fi
      sleep 60s
    done
		;;
	backup)
		echo "Starting cron scheduled backup and restore tasks..."
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
		echo "usage: sleep|bash|cron|backup|stage|restore"
    sleep 10s
		exit 1
esac




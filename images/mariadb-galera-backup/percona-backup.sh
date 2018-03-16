#!/bin/bash

echo "Running the MariaDB backup service..."

PERCONA_BACKUP_HOST_FILE=${PERCONA_BACKUP_HOST_FILE:-/run/secrets/db-backup-xtrabackup_host}
if [ -z $PERCONA_BACKUP_HOST ] && [ -f $PERCONA_BACKUP_HOST_FILE ]; then
	PERCONA_BACKUP_HOST=$(cat $PERCONA_BACKUP_HOST_FILE)
fi
[ -z $PERCONA_BACKUP_HOST ] && { echo "PERCONA_BACKUP_HOST not set"; exit 1; }

PERCONA_BACKUP_USER_FILE=${PERCONA_BACKUP_USER_FILE:-/run/secrets/db-backup-xtrabackup_user}
if [ -z $PERCONA_BACKUP_USER ] && [ -f $PERCONA_BACKUP_USER_FILE ]; then
	PERCONA_BACKUP_USER=$(cat $PERCONA_BACKUP_USER_FILE)
fi
[ -z $PERCONA_BACKUP_USER ] && { echo "PERCONA_BACKUP_USER not set"; exit 1; }

PERCONA_BACKUP_PASSWORD_FILE=${PERCONA_BACKUP_PASSWORD_FILE:-/run/secrets/db-backup-xtrabackup_password}
if [ -z $PERCONA_BACKUP_PASSWORD ] && [ -f $PERCONA_BACKUP_PASSWORD_FILE ]; then
	PERCONA_BACKUP_PASSWORD=$(cat $PERCONA_BACKUP_PASSWORD_FILE)
fi
[ -z $PERCONA_BACKUP_PASSWORD ] && { echo "PERCONA_BACKUP_PASSWORD not set"; exit 1; }

RETENTION_PERIOD_FILE=${RETENTION_PERIOD_FILE:-/run/secrets/db-backup-xtrabackup_retention}
if [ -z $RETENTION_PERIOD_DAYS ] && [ -f $RETENTION_PERIOD_FILE ]; then
	RETENTION_PERIOD_DAYS=$(cat $RETENTION_PERIOD_FILE)
fi
if [ -z $RETENTION_PERIOD_DAYS ]; then
  RETENTION_PERIOD_DAYS=7
fi


# the CURRENT_INC determines the period of the incremental backup
# if the folder exists, the backup is considered complete.

BACKUP_HOUR=`date +%H`
BACKUP_MINUTE=`date +%M`
DAY_OF_YEAR=`date +%j`

CURRENT_DATE_STAMP=`date +%Y_%m_%d`
CURRENT_BASE=day_${DAY_OF_YEAR}_${CURRENT_DATE_STAMP}
CURRENT_INC=${BACKUP_HOUR}_${BACKUP_MINUTE}

TARGET_FOLDER=/target/$CURRENT_BASE
FULL_BACKUP_FOLDER=$TARGET_FOLDER/base
INC_BACKUP_FOLDER=$TARGET_FOLDER/inc_$CURRENT_INC
NOW=`date`

echo "---"
echo "MariaDB Backup Agent"
echo "---"
echo "Host: ${PERCONA_BACKUP_HOST}"
echo "User: ${PERCONA_BACKUP_USER}"
echo "Target Folder: ${TARGET_FOLDER}"
echo "Full Backup Folder: ${FULL_BACKUP_FOLDER}"
echo "Incremental Backup Folder: ${INC_BACKUP_FOLDER}"
echo "Incremental Backup Interval: ${INC_BACKUP_INTERVAL}"
echo "---"
echo "Current Timestamp: ${NOW}"

DEAD_BASE_DATE=`date --date="${RETENTION_PERIOD_DAYS} days ago" +"%Y_%m_%d"`
DEAD_BASE_DAY=`expr $DAY_OF_YEAR - ${RETENTION_PERIOD_DAYS}`
DEAD_BASE_FOLDER=day_${DEAD_BASE_DAY}_${DEAD_BASE_DATE}
echo "Checking for expired backup to purge: ${DEAD_BASE_FOLDER}"
DEAD_TARGET_FOLDER=/target/$DEAD_BASE_FOLDER
if [ -d $DEAD_TARGET_FOLDER ]; then 
  echo ">>>"
  echo ">>> Purging Backup: ${DEAD_BASE} from ${RETENTION_PERIOD_DAYS} days ago..."
  echo ">>>"
  rm -rf $DEAD_TARGET_FOLDER
  echo 
fi

if [ ! -d $TARGET_FOLDER ]; then
  mkdir -p $TARGET_FOLDER
fi

if [ ! -d $FULL_BACKUP_FOLDER ]; then
  echo "Running the FULL Backup..."
  START_TIME=$SECONDS
  xtrabackup --backup --compress --compress-threads=4 \
    --host=$PERCONA_BACKUP_HOST --user=$PERCONA_BACKUP_USER --password=$PERCONA_BACKUP_PASSWORD \
    --datadir /var/lib/mysql --target-dir=$FULL_BACKUP_FOLDER
  if [ $? -ne 0 ]; then
    echo "!!! Failed! Full Backup!"
  fi
  echo "FULL Backup complete ${FULL_BACKUP_FOLDER}"
  echo
  ELAPSED_TIME=$(($SECONDS - $START_TIME))
  echo "FULL Backup Completed in: $(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec" 
  echo
else 
  if [ -n $INC_BACKUP_FOLDER ] && [ ! -d $INC_BACKUP_FOLDER ]; then
    START_TIME=$SECONDS
    LAST_INC_BACKUP=$(ls -t ${TARGET_FOLDER} | grep inc_ | head -1) 
    if [ "$LAST_INC_BACKUP" == "" ]; then 
      LAST_INC_BACKUP=base
    fi
    echo "Running the INCREMENTAL Backup for target base: ${LAST_INC_BACKUP}..."
    xtrabackup --backup --compress --compress-threads=4 \
      --host=$PERCONA_BACKUP_HOST --user=$PERCONA_BACKUP_USER --password=$PERCONA_BACKUP_PASSWORD \
      --target-dir=$INC_BACKUP_FOLDER \
      --incremental-basedir=$TARGET_FOLDER/$LAST_INC_BACKUP
    if [ $? -ne 0 ]; then
      echo "!!! Failed! Incremental Backup!"
    fi
    echo "INCREMENTAL Backup complete ${INC_BACKUP_FOLDER}"
    echo
		ELAPSED_TIME=$(($SECONDS - $START_TIME))
		echo "INCREMENTAL Backup Completed in: $(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec" 
		echo
    
  else
    echo "Backups are up to date - nothing to do."
    echo
  fi    
fi


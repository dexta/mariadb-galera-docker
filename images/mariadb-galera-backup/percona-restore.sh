#!/bin/bash

echo "Running the MariaDB Galera primary restore service..."

export BACKUPS_FOLDER=/backups
if [ -z $SOURCE_BACKUP ]; then
	echo "** SOURCE_BACKUP must be specified!"
	exit 1
fi

if [ "$SOURCE_BACKUP" == "latest" ]; then
	SOURCE_BACKUP=$(ls -t $BACKUPS_FOLDER | head -1) 
fi 

export SOURCE_BACKUP_FOLDER=$BACKUPS_FOLDER/$SOURCE_BACKUP
if [ ! -d $SOURCE_BACKUP_FOLDER ]; then
	echo "** SOURCE_BACKUP_FOLDER does not exist!"
	echo "SOURCE_BACKUP_FOLDER: ${SOURCE_BACKUP_FOLDER}"
	exit 1
fi 
if [ ! -d $SOURCE_BACKUP_FOLDER/base ]; then
	echo "** SOURCE_BACKUP_FOLDER does not contain a base full backup!"
	echo "Please ensure SOURCE_BACKUP_FOLDER points to the root target backup folder!"
	echo "SOURCE_BACKUP_FOLDER: ${SOURCE_BACKUP_FOLDER}"
	exit 1
fi 

export TEMP_WORKING_FOLDER=/temp 
if [ ! -d $TEMP_WORKING_FOLDER ]; then
	echo "** TEMP_WORKING_FOLDER does not exist!"
	echo "TEMP_WORKING_FOLDER: ${TEMP_WORKING_FOLDER}"
	exit 1
fi 

export TARGET_DATA_FOLDER=/target 
if [ ! -d $TARGET_DATA_FOLDER ]; then
	echo "** TARGET_DATA_FOLDER does not exist!"
	echo "TARGET_DATA_FOLDER: ${TARGET_DATA_FOLDER}"
	exit 1
fi 

echo "---"
echo "MariaDB Restore Agent"
echo "---"
echo "Host: ${PERCONA_BACKUP_HOST}"
echo "User: ${PERCONA_BACKUP_USER}"
echo "Source Backup Folder: ${SOURCE_BACKUP_FOLDER}"
echo "Temp Working Folder: ${TEMP_WORKING_FOLDER}"
echo "Target Data Folder: ${TARGET_DATA_FOLDER}"
echo "---"
echo "Current Timestamp: ${NOW}"
echo

# Because the restoration process modifies the base backup, we will copy the root folder
# to another location before preparing and restoring
#
echo "Copying source backup files to temporary working folder..."
rsync -avrP $SOURCE_BACKUP_FOLDER $TEMP_WORKING_FOLDER

# https://www.percona.com/doc/percona-xtrabackup/LATEST/backup_scenarios/incremental_backup.html
#

# To apply the first incremental backup to the full backup, run the following command:
# $ xtrabackup --prepare --apply-log-only --target-dir=/data/backups/base  --incremental-dir=/data/backups/inc1

INC_COUNT=`ls -t ${TEMP_WORKING_FOLDER} | grep inc_ | sort | wc -l`
echo "INC_COUNT: ${INC_COUNT}"

INC_INDEX=0
if [ "$INC_COUNT" == "0" ]; then

	echo "** There are NO INCREMENTAL BACKUPS for this restore! **"
	echo "Preparing the full backup at $TEMP_WORKING_FOLDER/base..."
	xtrabackup --prepare --target-dir=$TEMP_WORKING_FOLDER/base

else

	# To prepare the base backup, you need to run xtrabackup --prepare as usual, but prevent the rollback phase:
	# $ xtrabackup --prepare --apply-log-only --target-dir=/data/backups/base
	echo "Preparing the base backup at $TEMP_WORKING_FOLDER/base..."
	xtrabackup --prepare --apply-log-only --target-dir=$TEMP_WORKING_FOLDER/base

	LAST_INC_BACKUP=$(ls -t ${TEMP_WORKING_FOLDER} | head -1) 

	for inc_folder in `ls -t ${TEMP_WORKING_FOLDER} | grep inc_ | sort`; do
			if [ "$inc_folder" != "$LAST_INC_BACKUP" ]; then
				# this must be the last incremental backup, so we don't do --apply-log-only
				echo "Preparing the FINAL increment: ${inc_folder}"
				xtrabackup --prepare --target-dir=$TEMP_WORKING_FOLDER/base --incremental-dir=$TEMP_WORKING_FOLDER/$inc_folder
			else 
				echo "Preparing the increment: ${inc_folder}"
				xtrabackup --prepare --apply-log-only --target-dir=$TEMP_WORKING_FOLDER/base --incremental-dir=$TEMP_WORKING_FOLDER/$inc_folder
			fi
	done

fi

echo "Purging target data folder..."
cd $TARGET_DATA_FOLDER
rm -rf *

# Now that the backups are prepared, we can restore the backup from the FULL
echo "Copying the restored data files to the target data folder"
rsync -avrP $TEMP_WORKING_FOLDER/base/** TARGET_DATA_FOLDER

echo "Cleaning up the Temp working area: ${TEMP_WORKING_FOLDER}"
cd ${TEMP_WORKING_FOLDER}
rm -rf *


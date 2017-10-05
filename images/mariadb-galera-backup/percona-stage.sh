HOUR=`date +%H`
DAY_OF_YEAR=`date +%j`

CURRENT_DATE_STAMP=`date +%Y_%m_%d`
CURRENT_BASE=day_${DAY_OF_YEAR}_${CURRENT_DATE_STAMP}
CURRENT_INC=$HOUR

TARGET_FOLDER=/target/day_$CURRENT_BASE
FULL_BACKUP_FOLDER=$TARGET_FOLDER/base
INC_BACKUP_FOLDER=$TARGET_FOLDER/inc$CURRENT_INC

echo
echo "---"
echo "Host: ${PERCONA_BACKUP_HOST}"
echo "User: ${PERCONA_BACKUP_USER}"
echo "Target Folder: ${TARGET_FOLDER}"
echo "Full Backup Folder: ${FULL_BACKUP_FOLDER}"
echo "Incremental Backup Folder: ${INC_BACKUP_FOLDER}"
echo "---"
echo

RETENTION_PERIOD_DAYS=7
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
  echo date
  echo "Running the FULL Backup..."
  xtrabackup --backup --compress --compress-threads=4 \
    --host=$PERCONA_BACKUP_HOST --user=$PERCONA_BACKUP_USER --password=$PERCONA_BACKUP_PASSWORD \
    --datadir /var/lib/mysql --target-dir=$FULL_BACKUP_FOLDER
  if [ $? -ne 0 ]; then
    echo "!!! Failed! Full Backup!"
  fi
  echo "FULL Backup complete ${FULL_BACKUP_FOLDER}"
  echo
else 
  if [ -n $INC_BACKUP_FOLDER ] && [ ! -d $INC_BACKUP_FOLDER ]; then
    echo date
    echo "Running the INCREMENTAL Backup..."
    xtrabackup --backup --compress --compress-threads=4 \
      --host=$PERCONA_BACKUP_HOST --user=$PERCONA_BACKUP_USER --password=$PERCONA_BACKUP_PASSWORD \
      --target-dir=$INC_BACKUP_FOLDER \
      --incremental-basedir=$FULL_BACKUP_FOLDER
    if [ $? -ne 0 ]; then
      echo "!!! Failed! Incremental Backup!"
    fi
    echo "INCREMENTAL Backup complete ${INC_BACKUP_FOLDER}"
    echo
  else
    echo "Backups are up to date - nothing to do."
    echo
  fi    
fi


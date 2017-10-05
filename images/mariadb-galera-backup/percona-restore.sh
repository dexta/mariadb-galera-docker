#!/bin/bash

echo "Running the MariaDB Galera primary restore service..."

PERCONA_BACKUP_HOST_FILE=${PERCONA_BACKUP_HOST_FILE:-/run/secrets/db-backup-xtrabackup_host}
if [ -z $PERCONA_BACKUP_HOST ] && [ -f $PERCONA_BACKUP_HOST_FILE ]; then
	PERCONA_BACKUP_HOST=$(cat $PERCONA_BACKUP_HOST_FILE)
fi
[ -z "$PERCONA_BACKUP_HOST" ] && { echo "PERCONA_BACKUP_HOST not set"; exit 1; }

PERCONA_BACKUP_USER_FILE=${PERCONA_BACKUP_USER_FILE:-/run/secrets/db-backup-xtrabackup_user}
if [ -z $PERCONA_BACKUP_USER ] && [ -f $PERCONA_BACKUP_USER_FILE ]; then
	PERCONA_BACKUP_USER=$(cat $PERCONA_BACKUP_USER_FILE)
fi
[ -z "$PERCONA_BACKUP_USER" ] && { echo "PERCONA_BACKUP_USER not set"; exit 1; }

PERCONA_BACKUP_PASSWORD_FILE=${PERCONA_BACKUP_PASSWORD_FILE:-/run/secrets/db-backup-xtrabackup_password}
if [ -z $PERCONA_BACKUP_PASSWORD ] && [ -f $PERCONA_BACKUP_PASSWORD_FILE ]; then
	PERCONA_BACKUP_PASSWORD=$(cat $PERCONA_BACKUP_PASSWORD_FILE)
fi
[ -z "$PERCONA_BACKUP_PASSWORD" ] && { echo "PERCONA_BACKUP_PASSWORD not set"; exit 1; }

RETENTION_PERIOD_FILE=${RETENTION_PERIOD_FILE:-/run/secrets/db-backup-xtrabackup_retention}
if [ -z $RETENTION_PERIOD_DAYS ] && [ -f $RETENTION_PERIOD_FILE ]; then
	RETENTION_PERIOD_DAYS=$(cat $RETENTION_PERIOD_FILE)
fi
[ -z "$RETENTION_PERIOD_DAYS" ] && { $RETENTION_PERIOD_DAYS=7 }

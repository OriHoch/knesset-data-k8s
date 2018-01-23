#!/usr/bin/env bash

DEFAULT_BACKUP_FREQUENCY_SECONDS=86400
DEFAULT_PGPASS=123456

[ -z "${BACKUP_FREQUENCY_SECONDS}" ] &&\
    echo "missing BACKUP_FREQUENCY_SECONDS, using default value of ${DEFAULT_BACKUP_FREQUENCY_SECONDS} seconds" &&\
    BACKUP_FREQUENCY_SECONDS="${DEFAULT_BACKUP_FREQUENCY_SECONDS}"

[ -z "${PGPASS}" ] &&\
    echo "missing PGPASS, using default value of ${DEFAULT_PGPASS}" &&\
    export PGPASS="${DEFAULT_PGPASS}"

if ! [ -e /state/db_ready ]; then
    echo "waiting for db server..."
    while ! psql -h 127.0.0.1 -U postgres -c "select 1"; do sleep 3; echo .; done

    if [ "${LAST_SYNC_URL}" != "" ]; then
        echo "attempting to download and import from last backup"
        gsutil cp "${LAST_SYNC_URL}/dump.sql" /last_sync.sql && ls -lah /last_sync.sql &&\
        echo "importing... (may take a while, depending on DB size)" &&\
        psql -h 127.0.0.1 -U postgres postgres < /last_sync.sql
    fi

    echo "Signaling to external apps that db is ready"
    touch /state/db_ready
fi

echo "LAST_SYNC_URL=${LAST_SYNC_URL}"
echo "sleeping ${BACKUP_FREQUENCY_SECONDS} until next backup..."
sleep ${BACKUP_FREQUENCY_SECONDS}

echo "exporting DB to sync data directory"
! pg_dump -h 127.0.0.1 -U postgres > "${DATA_PATH}/dump.sql" && echo "failed to create DB backup" && exit 1
ls -lah "${DATA_PATH}/dump.sql"

echo "delegating to pipelines sync to do the backup"
echo "after the sync the ops container will be restsarted"

touch "${STATE_PATH}/done"

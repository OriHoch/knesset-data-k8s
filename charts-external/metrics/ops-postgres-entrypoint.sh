#!/usr/bin/env bash

export DELAY_EXIT_SECONDS=""
export INITIAL_SYNC_SCRIPT="export LAST_SYNC_URL DATA_PATH STATE_PATH; /ops-postgres-initial-sync.sh"

/entrypoint.sh

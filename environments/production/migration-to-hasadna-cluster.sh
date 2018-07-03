#!/usr/bin/env bash

create_source_snapshot() {
    gcloud compute disks snapshot "${1}" --snapshot-names="${1}-migration-to-hasadna-cluster" \
                                         --project=hasadna-oknesset --zone=us-central1-a
}

get_source_snapshot_selfLink() {
    gcloud compute snapshots describe "${1}-migration-to-hasadna-cluster" --project=hasadna-oknesset --format json \
        | jq -r .selfLink
}

create_new_disk() {
    gcloud compute disks create "oknesset-${1}" --source-snapshot=$(get_source_snapshot_selfLink "${1}") \
                                                --project=hasadna-general --zone=europe-west1-b
}

create_source_snapshot migdar-data
create_source_snapshot publicdb
create_source_snapshot pipelines
create_new_disk migdar-data
create_new_disk publicdb
create_new_disk pipelines

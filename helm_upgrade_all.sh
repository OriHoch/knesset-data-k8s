#!/usr/bin/env bash

source connect.sh

RES=0

echo "Upgrading all charts of ${K8S_ENVIRONMENT_NAME} environment"
for CHART_NAME in `ls charts-external`; do
    if [ "${CHART_NAME}" == "pipelines" ]; then
        echo "Skipping deployment of pipelines"
        echo "it's hot reloaded so you will have to deploy manually for infrastructure changes"
    else
        ./helm_upgrade_external_chart.sh "${CHART_NAME}" "$@"
        [ "$?" != "0" ] && echo "failed ${CHART_NAME} upgrade" && RES=1;
    fi
done

exit $RES

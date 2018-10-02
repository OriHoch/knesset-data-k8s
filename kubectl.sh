#!/usr/bin/env bash

get_pod_name() {
    ! kubectl get pods -l "app=${1}" -o 'jsonpath={.items[0].metadata.name}' \
        && echo > /dev/stderr && echo "Error: couldn't find pod matching label app=${1}" >/dev/stderr && return 1
    return 0
}

get_secrets_json() {
    kubectl get secret $1 -o json
}

get_secret_from_json() {
    VAL=`echo "${1}" | jq -r ".data.${2}"`
    if [ "${VAL}" != "" ] && [ "${VAL}" != "null" ]; then
        echo "${VAL}" | base64 -d
    fi
}

if [ "${1}" == "loop" ]; then
    # can be used to wait track progress of changes
    # e.g.
    # ./kubectl.sh loop get pods
    while true; do
        kubectl "${@:2}"
        sleep 1
    done

elif [ "${1} ${2}" == "port-forward knesset-data-infra" ]; then
    ./kubectl.sh port-forward publicdb 5432 &
    ./kubectl.sh port-forward tika 9998 &
    wait

elif [ "${1}" == "port-forward" ]; then
    # port-forward based on app label
    if [ "${3}" == "" ]; then
        PORT_FORWARD_DEFAULT_ARGS=""
        [ -e charts-external/${2}/default.sh ] && source charts-external/${2}/default.sh
        [ -z "${PORT_FORWARD_DEFAULT_ARGS}" ] && echo missing port-forward args && exit 1
        ARGS="${PORT_FORWARD_DEFAULT_ARGS}"
    else
        ARGS="${@:3}"
    fi
    ! POD_NAME=$(./kubectl.sh get-pod-name "${2}") && exit 1
    kubectl port-forward ${POD_NAME} $ARGS

elif [ "${1}" == "get-pod-name" ]; then
    # get pod name based on app label
    get_pod_name "${2}"

elif [ "${1}" == "exec" ]; then
    if [ "${3}" == "" ]; then
        EXEC_DEFAULT_ARGS=""
        [ -e charts-external/${2}/default.sh ] && source charts-external/${2}/default.sh
        [ -z "${EXEC_DEFAULT_ARGS}" ] && echo missing exec args && exit 1
        ARGS="${EXEC_DEFAULT_ARGS}"
    else
        ARGS="${@:3}"
    fi
    ! POD_NAME=$(./kubectl.sh get-pod-name "${2}") && exit 1
    kubectl exec "${POD_NAME}" $ARGS

elif [ "${1}" == "logs" ]; then
    if [ "${3}" == "" ]; then
        LOGS_DEFAULT_ARGS=""
        [ -e charts-external/${2}/default.sh ] && source charts-external/${2}/default.sh
        ARGS="${LOGS_DEFAULT_ARGS}"
    else
        ARGS="${@:3}"
    fi
    ! POD_NAME=$(./kubectl.sh get-pod-name "${2}") && exit 1
    kubectl logs "${POD_NAME}" $ARGS

elif [ "${1}" == "cp" ]; then
    ! POD_NAME=$(./kubectl.sh get-pod-name "${2}") && exit 1
    kubectl cp ${POD_NAME}:${@:3}

fi

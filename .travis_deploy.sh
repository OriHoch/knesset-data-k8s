#!/usr/bin/env bash

HELM_VERSION="v3.0.3"

if [ "${1}" == "install_helm" ]; then
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh &&\
  chmod 700 get_helm.sh &&\
  ./get_helm.sh --version "${HELM_VERSION}" &&\
  helm version --client --short | grep "${HELM_VERSION}+"
  exit $?
fi

echo "${TRAVIS_COMMIT_MESSAGE}" | grep -- --no-deploy && echo skipping deployment && exit 0

K8S_ENVIRONMENT_NAME="production-kamatera"
OPS_REPO_SLUG="OriHoch/knesset-data-k8s"
OPS_REPO_BRANCH="${TRAVIS_BRANCH}"
./run_docker_ops.sh "${K8S_ENVIRONMENT_NAME}" '
    RES=0;
    ./kubectl_patch_charts.py "'"${TRAVIS_COMMIT_MESSAGE}"'" --dry-run
    PATCH_RES=$?
    if [ "${PATCH_RES}" != "2" ]; then
        echo detected patches based on commit message
        if [ "${PATCH_RES}" == "0" ]; then
            ! ./kubectl_patch_charts.py "'"${TRAVIS_COMMIT_MESSAGE}"'" && echo failed patches && RES=1
            ! ./helm_healthcheck.sh && echo Failed healthcheck && RES=1
        else
            echo patches dry run failed && RES=1
        fi
    elif ./helm_upgrade_all.sh --install --dry-run --debug; then
        echo Dry run was successfull, performing upgrades
        ! ./helm_upgrade_all.sh --install && echo Failed upgrade && RES=1
        ! ./helm_healthcheck.sh && echo Failed healthcheck && RES=1
    else
        echo Failed dry run
        RES=1
    fi
    sleep 2;
    kubectl get pods;
    kubectl get service;
    exit "$RES"
' "orihoch/knesset-data-k8s-ops@sha256:a02e5dd7110e7e48ba1f8dea3fff4fbeab12eeab47f3e488b2160688053a0013" "${OPS_REPO_SLUG}" "${OPS_REPO_BRANCH}" "$RANCHER_ENDPOINT" "$RANCHER_TOKEN" \
    "-v /var/run/docker.sock:/var/run/docker.sock"
if [ "$?" == "0" ]; then
    echo travis deployment success
    exit 0
else
    echo travis deployment failed
    exit 1
fi

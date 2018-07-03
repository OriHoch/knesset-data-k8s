#!/usr/bin/env bash

echo "${TRAVIS_COMMIT_MESSAGE}" | grep -- --no-deploy && echo skipping deployment && exit 0

openssl aes-256-cbc -K $encrypted_2cdba463b699_key -iv $encrypted_2cdba463b699_iv -in ./k8s-ops-secret.json.enc -out secret-k8s-ops.json -d
K8S_ENVIRONMENT_NAME="production"
OPS_REPO_SLUG="OriHoch/knesset-data-k8s"
OPS_REPO_BRANCH="${TRAVIS_BRANCH}"
./run_docker_ops.sh "${K8S_ENVIRONMENT_NAME}" '
    RES=0;
    curl -L https://raw.githubusercontent.com/hasadna/hasadna-k8s/master/apps_travis_script.sh | bash /dev/stdin install_helm;
    if echo "'"${TRAVIS_COMMIT_MESSAGE}"'" | grep "automatic update of knesset-data-pipelines"; then
        kubectl set image --dry-run -o yaml deployment/pipelines "pipelines=$(eval echo $(./read_env_yaml.sh pipelines image))" &&\
        kubectl set image deployment/pipelines "pipelines=$(eval echo $(./read_env_yaml.sh pipelines image))" &&\
        bash charts-external/pipelines/healthcheck.sh
        [ "$?" != "0" ] && echo failed to update pipelines image && exit 1
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
' "orihoch/sk8s-ops" "${OPS_REPO_SLUG}" "${OPS_REPO_BRANCH}" "secret-k8s-ops.json"
if [ "$?" == "0" ]; then
    echo travis deployment success
    exit 0
else
    echo travis deployment failed
    exit 1
fi

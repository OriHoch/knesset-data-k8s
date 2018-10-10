#!/usr/bin/env bash

POD_SUFFIX="${1}"
IMAGE_NAME="${2}"

[ -z "${POD_SUFFIX}" ] && echo usage: utils/jupyter/start.sh '<UNIQUE_POD_SUFFIX> [JUPYTER_IMAGE_NAME]' && exit 1

TEMPFILE=`mktemp`

echo "
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: jupyter-${POD_SUFFIX}
spec:
  replicas: 1
  revisionHistoryLimit: 2
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: jupyter-${POD_SUFFIX}
    spec:
      securityContext:
        runAsUser: 0
      terminationGracePeriodSeconds: 5
      containers:
      - name: pipelines
        image: ${IMAGE_NAME}
        resources: {'requests': {'cpu': '200m', 'memory': '500Mi'}, 'limits': {'memory': '2Gi'}}
        command:
        - jupyter
        - lab
        - --allow-root
        - --NotebookApp.notebook_dir=jupyter-notebooks
        ports:
        - containerPort: 5000
        env:
        - name: DPP_DB_ENGINE
          valueFrom: {\"secretKeyRef\":{\"name\":\"publicdb\", \"key\":\"DPP_DB_ENGINE\"}}
        - name: DUMP_TO_STORAGE
          value: \"0\"
        - name: DUMP_TO_SQL
          value: \"0\"
        - name: GOOGLE_APPLICATION_CREDENTIALS
          value: /secret_service_key
        - name: DISABLE_MEMBER_PERCENTS
          value: `./read_env_yaml.sh pipelines DISABLE_MEMBER_PERCENTS`
        volumeMounts:
        - name: k8s-ops
          mountPath: /secret_service_key
          subPath: secret.json
          readOnly: true
        - mountPath: /pipelines/data
          name: data
          subPath: data
        - mountPath: /pipelines/dist
          name: data
          subPath: dist
      volumes:
      - name: k8s-ops
        secret:
          secretName: ops
      - name: data
        nfs:
          server: `./read_env_yaml.sh pipelines nfsServer`
          path: "/"
" > $TEMPFILE

! kubectl apply -f $TEMPFILE && cat $TEMPFILE
RES=$?

rm $TEMPFILE

[ "$RES" == "0" ] && echo Great Success

exit "$RES"

{{- define "pipeline-job" -}}
{{ if .enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .name | quote }}
spec:
  selector:
    app: {{ .name | quote }}
  ports:
  - name: "5000"
    port: 5000
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: {{ .name | quote }}
spec:
  replicas: 1
  revisionHistoryLimit: 2
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: {{ .name | quote }}
    spec:
      terminationGracePeriodSeconds: 0
      containers:
      {{ if .enableProxy }}
      - name: ssh-socks-proxy
        image: orihoch/ssh-socks-proxy@sha256:94faea572a5ff570d3dea92ca381909603e488c4162f36e56416648647ffd263
        resources: {"requests": {"cpu": "1m", "memory": "3Mi"}}
        env:
        - name: SSH_HOST
          value: ubuntu@db1.oknesset.org
        - name: SSH_PORT
          value: "22"
        - name: SOCKS_PORT
          value: "8123"
        - name: SSH_B64_KEY
          valueFrom:
            secretKeyRef:
              name: "ssh-socks-proxy"
              key: "SSH_B64_KEY"
        - name: SSH_B64_PUBKEY
          valueFrom:
            secretKeyRef:
              name: "ssh-socks-proxy"
              key: "SSH_B64_PUBKEY"
      {{ end }}
      - name: pipelines
        image: {{ .image | default .Values.image | quote }}
        resources:
          requests:
            cpu: "60m"
            memory: "500Mi"
        env:
        - name: METRICS_DB
          value: pipelines
        - name: METRICS_HOST
          value: http://metrics-influxdb:8086
        - name: METRICS_TAGS_PREFIX
          value: ",app={{ .name }},environment={{ .Values.global.environmentName }},pipeline="
        - name: INITIAL_SYNC_STATE_FILENAME
          value: synced
        - name: DONE_STATE_FILENAME
          value: done
        - name: EXIT_STATE_FILENAME
          value: exit
        - name: STATE_PATH
          value: /state
        {{ if .enableProxy }}
        - name: DATASERVICE_HTTP_PROXY
          value: socks5h://localhost:8123
        {{ end }}
        {{ if .allowPipelineOps }}
        - name: GOOGLE_APPLICATION_CREDENTIALS
          value: /k8s-ops/secret.json
        {{ end }}
        - name: DPP_DB_ENGINE
          valueFrom: {"secretKeyRef":{"name":"publicdb", "key":"DPP_DB_ENGINE"}}
        envFrom:
        - configMapRef:
            name: {{ .name }}-envfrom
        volumeMounts:
        - name: data
          mountPath: /pipelines/data
        - name: state
          mountPath: /state
        {{ if .allowPipelineOps }}
        - name: k8s-ops
          mountPath: /k8s-ops
          readOnly: true
        {{ end }}
      - name: ops
        image: gcr.io/uumpa-public/sk8s-google-storage-sync:v0.0.3b
        resources:
          requests:
            cpu: "1m"
            memory: "2Mi"
        env:
        - name: CLOUDSDK_CORE_PROJECT
          value: hasadna-oknesset
        - name: GS_BUCKET_NAME
          value: knesset-data-pipelines
        - name: OUTPUT_PATH_PREFIX
          value: {{ .outputPathPrefix | default "data/" }}
        - name: SYNC_ARGS
          value: "-a public-read"
        - name: DISABLE_TIMESTAMP
          value: "1"
        - name: DELAY_EXIT_SECONDS
          value: "86400"
        - name: DATA_PATH
          value: /pipelines/data
        - name: STATE_PATH
          value: /state
        {{ if .opsEnvFrom }}
        envFrom:
        - configMapRef:
            name: {{ .name }}-ops-envfrom
        {{ end }}
        volumeMounts:
        - name: data
          mountPath: /pipelines/data
        - name: state
          mountPath: /state
        - name: k8s-ops
          mountPath: /k8s-ops
          readOnly: true
      volumes:
      - name: data
        emptyDir: {}
      - name: state
        emptyDir: {}
      - name: k8s-ops
        secret:
          secretName: ops
{{ end }}
{{- end -}}

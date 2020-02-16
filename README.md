# Knesset Data Kubernetes Environment

## Connecting to the Kamatera environment

You should have KUBECONFIG environment var point to a kubeconfig file with access to the cluster

```
export KUBECONFIG=/path/to/kamatera-kubeconfig.yaml
```

Switch to the production-kamatera environment:

```
source switch_environment.sh production-kamatera
```

## Moving from Gcloud to Kamatera

Ssh to Kamatera NFS server:

```
mkdir -p /srv/default/oknesset/pipelines/data
mkdir -p /srv/default/oknesset/publicdb/data
```

Modify /etc/exports in the Kamatera NFS server to allow access from the Gcloud nodes

Define functions:

```
get_pod_name() {
    local NAMESPACE=$1
    local POD_PREFIX=$2
    kubectl get pods -n $NAMESPACE | grep $POD_PREFIX | cut -d " " -f 1
}

get_pod_node_name() {
    local NAMESPACE=$1
    local POD_PREFIX=$2
    kubectl get -n $NAMESPACE pod `get_pod_name $NAMESPACE $POD_PREFIX` -o yaml | grep nodeName: | cut -d " " -f 4
}

get_pod_uid() {
    local NAMESPACE=$1
    local POD_PREFIX=$2
    kubectl get -n $NAMESPACE pod `get_pod_name $NAMESPACE $POD_PREFIX` -o yaml | grep '^  uid' | cut -d " " -f 4
}

mount_nfs_and_rsync() {
    local NODE_NAME=$1
    local NFS_IP=$2    
    local SOURCE_DIR=$3
    local TARGET_DIR=$4
    local NFS_TARGET_DIR=$5
    echo mounting NFS and rsyncing &&\
    echo NODE_NAME=$NODE_NAME &&\
    echo NFS_IP=$NFS_IP &&\
    echo SOURCE_DIR=$SOURCE_DIR &&\
    echo TARGET_DIR=$TARGET_DIR &&\
    echo NFS_TARGET_DIR=$NFS_TARGET_DIR &&\
    gcloud compute ssh $NODE_NAME -- toolbox bash -c '"apt-get update && apt-get install -y nfs-common rsync && mkdir -p '$TARGET_DIR'"' &&\
    gcloud compute ssh $NODE_NAME -- toolbox bash -c '"mount -t nfs '$NFS_IP':'$NFS_TARGET_DIR' '$TARGET_DIR' && rsync --progress -az '$SOURCE_DIR' '$TARGET_DIR'"'
}
```

Set the Kamatera NFS server ip:

```
TARGET_NFS_IP=212.80.204.62
```

Rsync publicdb data:

```
mount_nfs_and_rsync `get_pod_node_name oknesset publicdb-` $TARGET_NFS_IP \
                    /media/root/var/lib/kubelet/pods/$PUBLICDB_POD_UID/volumes/kubernetes.io~gce-pd/ \
                    /media/root/var/kamatera-nfs/oknesset-publicdb-data \
                    /srv/default/oknesset/publicdb/data/
```

Rsync pipelines data (run from NFS node):

```
CLOUDSDK_CORE_PROJECT=hasadna-oknesset gsutil \
    rsync -J -R gs://knesset-data-pipelines/data/dist /srv/default/oknesset/pipelines/data/committees/dist/dist
```

```
for DIR in bills committees knesset laws lobbyists members people plenum votes; do
  CLOUDSDK_CORE_PROJECT=hasadna-oknesset gsutil \
      rsync -J -R gs://knesset-data-pipelines/data/$DIR/ /srv/default/oknesset/pipelines/data/oknesset-nfs-gcepd/data/$DIR/
done
```

Connect to the Gcloud environment and export the secrets:

```
mkdir -p environments/production-kamatera/.secrets &&\
kubectl get -n oknesset secret nginx-htpasswd --export -o yaml > environments/production-kamatera/.secrets/nginx-htpasswd.yaml &&\
kubectl get -n oknesset secret redash-reader --export -o yaml > environments/production-kamatera/.secrets/redash-reader.yaml &&\
kubectl get -n oknesset secret publicdb --export -o yaml > environments/production-kamatera/.secrets/publicdb.yaml &&\
kubectl get -n oknesset secret ops --export -o yaml > environments/production-kamatera/.secrets/ops.yaml &&\
kubectl get -n oknesset secret ssh-socks-proxy --export -o yaml > environments/production-kamatera/.secrets/ssh-socks-proxy.yaml
```

Connect to the Kamatera environment, import the secrets and delete local copies:

```
export KUBECONFIG=/path/to/kamatera/kubeconfig
kubectl create ns oknesset || true &&\
kubectl -n oknesset apply -f environments/production-kamatera/.secrets/nginx-htpasswd.yaml &&\
kubectl -n oknesset apply -f environments/production-kamatera/.secrets/redash-reader.yaml &&\
kubectl -n oknesset apply -f environments/production-kamatera/.secrets/publicdb.yaml &&\
kubectl -n oknesset apply -f environments/production-kamatera/.secrets/ops.yaml &&\
kubectl -n oknesset apply -f environments/production-kamatera/.secrets/ssh-socks-proxy.yaml &&\
rm -rf environments/production-kamatera/.secrets
```

Switch to the Kamatera environment and deploy the DB:

```
export KUBECONFIG=/path/to/kamatera/kubeconfig
source switch_environment.sh production-kamatera
kubectl get nodes
./helm_upgrade_external_chart.sh publicdb --deploy --install
```

Change DNS of publicdb to the public IP of the node it's scheduled on

update the environment's `values.yaml` and set the db nodeSelector to this node

deploy: `./helm_upgrade_external_chart.sh publicdb --deploy`

When DB is running, deploy the pipelines:

```
./helm_upgrade_external_chart.sh pipelines --deploy --install
```

When Pipelines are running, deploy nginx:

```
./helm_upgrade_external_chart.sh nginx --deploy --install
```

## More Info

See the [sk8s documentation](https://github.com/OriHoch/sk8s/blob/master/README.md)

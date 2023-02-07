# Knesset Data Kubernetes Environment

Infrastructure is defined as a helm charts under `apps/`

The charts are continuously synced to Hasadna cluster via ArgoCD as defined [here](https://github.com/hasadna/hasadna-k8s/blob/master/apps/hasadna-argocd/values-hasadna.yaml).

## Update MOT Node Allowed IPs

Some operations have to run from allowed IPs on Knesset. The following command updates the node labels according to the
latest requested allowed IPs:

```
python3 bin/update_node_allowed_ips.py
```

If you need to request or change the allowed IPs, edit that file and set the `ALLOWED_IPS` constant.

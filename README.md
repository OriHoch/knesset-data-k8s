# Knesset Data Kubernetes Environment

Infrastructure is defined as a helm charts under `apps/`

The charts are continuously synced to Hasadna cluster via ArgoCD as defined [here](https://github.com/hasadna/hasadna-k8s/blob/master/apps/hasadna-argocd/values-hasadna.yaml).

## Connecting to the Kamatera environment

You should have KUBECONFIG environment var point to a kubeconfig file with access to the cluster

```
export KUBECONFIG=/path/to/kamatera-kubeconfig.yaml
```

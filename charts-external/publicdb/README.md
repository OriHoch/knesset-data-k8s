# Public DB

DB contains all the public data and is accessed remotely using read-only user by Redash


## Secrets

```
 kubectl create secret generic publicdb --from-literal=POSTGRES_PASSWORD=******
```


## Deployment

```
./helm_upgrade_external_chart.sh publicdb --install --dry-run --debug \
&& ./helm_upgrade_external_chart.sh publicdb --install
```


## Connect to the DB with adminer

enable adminer in the publicdb values:

```
publicdb:
  adminerEnabled: true
```

Deploy the publicdb chart and setup port forward to the publicdb pod, adminer port

```
kubectl port-forward publicdb-<TAB><TAB> 8080
```

* http://localhost:8080
  * System: PostgreSQL, Server: localhost, Username: publicdb, Password: *******, Database: publicdb

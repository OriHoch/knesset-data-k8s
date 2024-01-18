# Public DB

DB contains all the public data and is accessed remotely using read-only user by Redash


## Secrets

```
 POSTGRES_PASSWORD=******
kubectl create secret generic publicdb --from-literal=POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
                                        --from-literal=DPP_DB_ENGINE=postgresql://postgres:${POSTGRES_PASSWORD}@publicdb:5432/postgres
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


## Create read only user for redash

```
CREATE ROLE readaccess;
GRANT USAGE ON SCHEMA public TO readaccess;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readaccess;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readaccess;
CREATE USER redash_reader WITH PASSWORD '*******';
GRANT readaccess TO redash_reader;
```

## Set limitations on the read only redash users

```
ALTER ROLE redash_reader SET idle_in_transaction_session_timeout = '10min';
ALTER ROLE redash_reader SET statement_timeout = '5min';
ALTER ROLE redash_reader SET lock_timeout = '5s';
```

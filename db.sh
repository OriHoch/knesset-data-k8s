#!/bin/sh
kubectl exec -it -c publicdb $(kubectl get pods -l app=publicdb -o 'jsonpath={.items[0].metadata.name}') \
    -- bash -c 'su postgres sh -c "psql postgres"'

#!/usr/bin/env bash

kubectl rollout status deployment/metrics-grafana &&\
kubectl rollout status deployment/metrics-influxdb

# Metrics

Provide easy to use infrastructure for internal app metrics collection and visualization.

## Sending metrics

Port forward the influxDB pod to test locally

```
kubectl port-forward metrics-influxdb-<TAB><TAB> 8086
```

Create a test DB

```
curl -i -XPOST http://localhost:8086/query --data-urlencode \
    "q=CREATE DATABASE test"
```

Send some metrics

```
curl -i -XPOST 'http://localhost:8086/write?db=test' --data-binary \
    'num_of_items_in_queue,environment=production,app=spark value=32'
curl -i -XPOST 'http://localhost:8086/write?db=test' --data-binary \
    'num_of_items_in_queue,environment=testing,app=spark value=11'
sleep 1
curl -i -XPOST 'http://localhost:8086/write?db=test' --data-binary \
    'num_of_items_in_queue,environment=production,app=foobar value=55'
curl -i -XPOST 'http://localhost:8086/write?db=test' --data-binary \
    'num_of_items_in_queue,environment=testing,app=spark value=3'
sleep 1
curl -i -XPOST 'http://localhost:8086/write?db=test' --data-binary \
    'num_of_items_in_queue,environment=production,app=foobar value=66'
curl -i -XPOST 'http://localhost:8086/write?db=test' --data-binary \
    'num_of_items_in_queue,environment=testing,app=spark value=0'
sleep 1
curl -i -XPOST 'http://localhost:8086/write?db=test' --data-binary \
    'num_of_items_in_queue,environment=production,app=foobar value=99'
curl -i -XPOST 'http://localhost:8086/write?db=test' --data-binary \
    'num_of_items_in_queue,environment=testing,app=spark value=0'
```

## Visualize the metrics

Port forward the Gradana pod

```
kubectl port-forward metrics-grafana-<TAB><TAB> 3000
```

Login to grafana

* http://localhost:3000
* admin / admin

Add the InfluxDB data source

* name: test (uncheck default)
* type: influxdb
* url: http://metrics-influxdb:8086
* access: direct
* InfluxDB Database: test
* Min time interval: 1s

Add a new dashboard to visualize this data

* Dashboards > Add Graph
* Click on the panel title, then edit
* Data source = test
* Select measurement: num_of_item_in_queue
* group by: tag(environment), tag(app)
* top right corner - choose appropriate time range
* drag to zoom into the metrics we sent

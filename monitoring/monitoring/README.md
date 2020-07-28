# Umbrella chart for Platform Monitoring Components

Install all Platform monitoring components:
```
helm install monitoring charts/monitoring --wait 
  --set global.monitoring_tag=3.6.0.0-849.d6b2e785
  --namespace=kube-monitor
```
Below variables should be added if you want to send logs to external logstash service.
Specify ip and port accordingly.
```
  --set rsyslog.logReceiver.enable=true
  --set rsyslog.logReceiver.host=127.0.0.1
  --set rsyslog.logReceiver.port=9600
```


## Flex v1 Longevity System Monitoring
Download latest stable monitoring Helm charts [monitoring-0.0.1.tgz](http://asdrepo.isus.emc.com:8081/artifactory/ecs-build/com/emc/asd/vipr/monitoring/lastSuccessfulBuild/charts/monitoring-0.0.1.tgz).
Install system monitoring for the cluster:
```
helm install monitoring monitoring-0.0.1.tgz \
--set global.monitoring_registry=harbor.lss.emc.com/atlantic \
--set global.tls_enabled=false \
--set global.communication_scheme=http \
--set global.influxdb_replicas=1 \
--set global.monitoring_tag=latest \
--set grafana.service.type=LoadBalancer \
--set global.rsyslog_enabled=false \
--set global.internal_dns=kube-dns.kube-system.svc.cluster.local \
--set telegraf-ds.resources.requests.memory=50Mi \
--set influxdb.resources.requests.memory=50Mi \
--set influxdb.persistence.storageClassName=vsphere \
--set fluxd.resources.requests.memory=50Mi \
--set throttler.resources.requests.memory=50Mi \
--set telegraf.resources.requests.memory=50Mi \
--set grafana.resources.requests.memory=50Mi \
-n kube-monitor
```

Find the external ip of Grafana:
```
kubectl get svc -n kube-monitor | grep grafana
```

## Grafana Integration with Keycloak
Pass the following values to `helm install` to set up auth with Keycloak:

```
--set grafana.config.oauth.enabled=true
--set grafana.config.oauth.auth_url=http://<EXTERNAL_KC_ADDR>:<KEYCLOAK_PORT>/auth/realms/<REALM_NAME>/protocol/openid-connect/auth
--set grafana.config.oauth.token_url=http://<KEYCLOAK_SVC>:<KEYCLOAK_PORT>/auth/realms/<REALM_NAME>/protocol/openid-connect/token
--set grafana.config.oauth.api_url=http://<KEYCLOAK_SVC>:<KEYCLOAK_PORT>/auth/realms/<REALM_NAME>/protocol/openid-connect/userinfo
--set grafana.config.oauth.signout_url=http://<EXTERNAL_KC_ADDR>:<KEYCLOAK_PORT>/auth/realms/<REALM_NAME>/protocol/openid-connect/userinfo
--set grafana.config.oauth.client_id=<CLIENT_ID>
--set grafana.config.oauth.client_secret=<CLIENT_SECRET>
```

Note: Grafana should be aware of its externally accessible URL to communicate with Keycloak.
Use reverse proxy settings to configure Grafana with external address.

## Grafana Integration with Reverse Proxy (API Server)
Pass the following values to `helm install` to set up integration with reverse proxy:

```
--set grafana.config.reverse_proxy.enabled=true
--set grafana.config.reverse_proxy.protocol=http/https
--set grafana.config.reverse_proxy.domain=EXTERNAL_PROXY_ADDR:PORT
--set grafana.config.reverse_proxy.subpath=PROXY_SUBPATH_FOR_GRAFANA
```

## Reconfigure Telegraf for external monitoring
Use command below to enable and configure telegraf for external monitoring
```
helm install monitoring-configs ./charts/telegraf-external-config
--set global.enable_external_telegraf_endpoint=true
--set global.external_telegraf_endpoint_ip="127.0.0.1"
--set global.cluster_name="cluster-name"
```

## Alerts

Alert Manager is responsible for sending alerts based on TSDB data. It is running in Throttler pod.
Alerting is enabled in Platform monitoring by default.

### How to Add New Alert

1. Add alert definition to `charts/monitoring/alerts.yaml` with the following fields:
```
id: ID of the alert, used to find corresponding Flux query file
enabled: true/false
range: range of the Flux query in format of Go Duration, e.g. 1h
reason: event reason passed to K8S;
message: event message passed to K8S; supports Prometheus templating
         supports Prometheus templating with labels ( {{ $labels.<LABEL_NAME> }} )
         and value ( {{ $value }} )
symptoms: list of symptoms with severity types and additional information for KAHM
  - id: symptom ID
    type: list of severity types (Info/Warning/Error/Critical)
    event_rule: used by KAHM to match notification channel with Symptom ID
      description: KAHM event rule description
      notifiers: list of notifiers for KAHM
    event_remedy: used by KAHM to describe remedy for alert
      description: KAHM event remedy description
      remedies: list of remedies, for example references to KB articles
```
2. Put Flux query into file named `alert_<ALERT_ID>.flux` in directory `charts/throttler/alerts/platform`.
`<ALERT_ID>` should match the ID set in alert definition.
Query should contain templated range and output table with fields for event generation, for example:
```
from(bucket: "monitoring_op")
|> filter(fn: (r) => ... ))
|> range(start: {{ .Start }}, stop: {{ .Stop }})
...
|> map(fn: (r) => ({
 _value: r._value,
 _type: "Warning"
}))
```
Each line in table is sent as a separate event.

#### Output table rules
1. `_value` column should be present in output table. All types except `string` are supported.
2. Alerts are distinguished by a set of labels. Labels are string columns included in group key of the table.
Ensure that output table is grouped by required columns.
For example, if there is `host` label in alert, call `group` by `host` before final `map`:
```
...
|> group(columns: ["host"])
|> map(fn: (r) => ({
 _value: r._value,
 _type: "Critical"
}))
```
Then `host` may be used in message template:
```
message: "Data recorded in TSDB is lagging by 30 mins on node {{ $labels.host }}"
```

# Telegraf Config With Output for external Monitoring

Deploy Additional Telegraf Config map to configure pods to send metrics to external monitoring node.

```
helm install monitoring-configs ./charts/telegraf-external-config
--set global.enable_external_telegraf_endpoint=true
--set global.external_telegraf_endpoint_ip="127.0.0.1"
--set global.cluster_name="cluster-name"
```
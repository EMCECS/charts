# Telegraf Deployment Chart

Deploy Telegraf Deployment to collect metrics from apps running on k8s
by polling apps metrics endpoints.
Single instance is deployed.

```
helm install monitoring ./charts/monitoring/telegraf
```
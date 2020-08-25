# Umbrella charts for Obectscale Monitoring Components

Install all Obectscale monitoring components:
```
helm install objectscale-monitoring ./charts/objectscale-monitoring
```

Install objectscale monitoring on VSphere cluster. Below options that should be added to 
```helm template objectscale-manager ./objectscale-manager``` cmd in main Makefile in charts repository:
```
--set global.monitoring_registry=asdrepo.isus.emc.com:9042
--set ecs-monitoring.influxdb.persistence.storageClassName=dellemc-objectscale-local
--set global.monitoring.enabled=true
--set global.monitoring_tag=green
```

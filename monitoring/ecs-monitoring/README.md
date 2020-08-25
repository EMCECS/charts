# Umbrella charts for ECS Monitoring Components

Install all ECS monitoring components:
```
helm install ecs-monitoring ./charts/ecs-monitoring
```

Install objectstore with ecs monitoring on VSphere cluster:
```
helm install ecs-flex ./charts/ecs-cluster --set global.registry=asdrepo.isus.emc.com:8099
 --set global.monitoring_registry=asdrepo.isus.emc.com:9042 --set storageServer.persistence.size=300Gi
 --set performanceProfile=Large --set tag=shippable  --set provision.image.tag=shippable
 --set storageClassName=vsphere --set fabricProxy.image.tag=shippable
 --set managementGateway.image.tag=shippable --set diagnostic.dtHealthImage.tag=shippable
 --set zookeeper.image.tag=shippable --set managementGateway.service.type=LoadBalancer
 --set s3.service.type=LoadBalancer --set diagnostic.service.type=LoadBalancer
 --set provision.enabled=True --set fluentbitAgent.image.tag=stable --set accessKey=bWyewlzvQnhs
 --set storageServer.persistence.protected=False
 --set ecs-monitoring.influxdb.persistence.storageClassName=dellemc-objectscale-local
 --set atlas.persistence.storageClassName=dellemc-objectscale-highly-available
 --set zookeeper.persistence.storageClassName=dellemc-objectscale-highly-available
 --set storageServer.persistence.volumesCount=3 --set storageServer.replicas=3
 --set storageServer.persistence.storageClassName=dellemc-objectscale-local
 --set global.monitoring.enabled=true --set features.enableAdvancedStatistics=false
 --set global.monitoring_tag=green --set global.rsyslog_enabled=false
```

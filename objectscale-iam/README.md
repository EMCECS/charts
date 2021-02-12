#Dell EMC IAM  Helm Chart

This Helm chart deploys a Dell EMC IAM Service and its dependencies.

## Table of Contents

* [Description](#description)
* [Helm Settings](#helm install settings)

## Description

The Dell EMC IAM Service is a subchart of objectscale-manager.

- The Iam Service name is "objectscale-iam" and eploys as a LoadBalancer with external IP on port 9400. 
- The feature is enabled by default and integrated with objectstore (ecs-cluster) provisioning via the iam client. 
- It requires  atlas instance with persistent volume claim (Retain)

## helm install settings
By default the iam service and atlas number of replicas is set to 3.
To decrease the number of replicas of the objectscale-iam service (_recommended for single node installs_) use:
```bash
  --set objectscale-iam.replicaCount=1
```

**Important: For single node deployments, set objectscale-iam.atlas replicas to 1.**

To decrease the number of replicas use:
```bash
  --set objectscale-iam.atlas.replicaCount=1
```

By default, atlas affinity is set to false. If installing on a single node with replicaCount=3 (_not recommended_), you must also set affinity:
```bash
  --set objectscale-iam.atlas.disableAntiAffinity=true
```



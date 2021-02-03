#Dell EMC IAM  Helm Chart

This Helm chart deploys a Dell EMC IAM Service and its dependencies.

## Table of Contents

* [Description](#description)

## Description

The Dell EMC IAM Service is a subchart of objectscale-manager.

- The Iam Service name is "objectscale-iam" and eploys as a LoadBalancer with external IP on port 9400. 
- The feature is enabled by default and integrated with objectstore provisioning via the iam client. 
- It requires  atlas instance with persistent volume claim (Retain)


By default the iam service and atlas number of replicas is set to 3.
To decrease the number of replicas of the objectscale-iam service use:
```bash
  --set objectscale-iam.replicaCount=1
```

For single node deployments, set atlas replicas to 1.
To decrease the number of replicas use:
```bash
  --set objectscale-iam.atlas.replicaCount=1
```

By default,atlas affinity is set to false. When installing on single a node with replicaCount=3, you will also need to set affinity:
```bash
  --set objectscale-iam.atlas.disableAntiAffinity=true
```
Additional settings include:
```bash
   --set objectscale-iam.image.registry=
   --set objectscale-iam.image.repository=
   --set objectscale-iam.image.tag=
```


#Dell EMC IAM  Helm Chart

This Helm chart deploys a Dell EMC IAM Service and its dependencies.

## Table of Contents

* [Description](#description)

## Description

The Dell EMC IAM Service is 2 k8s pods:
- atlas instance with persistent volume claim (Retain)
- iamservice controller to support accounts,  iam entities and iamclient requests

By default the iam feature is not enabled in objectscale-manager.

To enable iam on the install - include:
```bash
  --set iam.enabled=true
```


You can specify a different repository for iam using:
```bash
  --set iam.atlas.registry=<repo>
```



By default the iam number of replicas is set to 3.
To decrease the number of replicas use:
```bash
  --set iam.atlas.replicaCount=1
```

By default,atlas affinity is set to false. When installing on single a node with replicaCount=3, you will also need to set affinity:
```bash
  --set iam.atlas.affinity=true
```



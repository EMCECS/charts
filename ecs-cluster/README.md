# Dell EMC Elastic Cloud Storage (ECS) Helm Chart

This Helm chart deploys a fully functional Dell EMC Elastic Cloud Storage (ECS) S3-compatible storage system.

## Table of Contents
* [Description](#description)
* [Requirements](#requirements)
* [Quick Start](#quick-start)
* [Configuration](#configuration)
* [Private Kubernetes Storage Class Setup](#sc-setup)

## Description

Dell EMC Elastic Cloud Storage is a highly-scalable, enterprise, S3-compatible object storage platform. This Helm chart deploys a fully-functional ECS Cluster instance on a Kubernetes cluster.

## Requirements

* A [Helm 3](https://helm.sh) installation with access to install to one or more namespaces.
* [ObjectScale Manager](https://github.com/EMCECS/charts/tree/master/objectscale-manager). Only a single operator needs to be installed for a monitored namespace or Kubernetes cluster.
* A Kubernetes Storage Class capable of dynamically creating `ReadWriteOnce` (`RWO`) volumes. This is available in many public Kubernetes services, such as AWS EKS and Google GKE. For more information see the [storage class section](#sc-setup) below.

## Quick Start

1. First, [install and setup Helm](https://docs.helm.sh/using_helm/#quickstart).  *_Note:_* you'll likely need to setup role-based access controls for Helm to have rights to install packages, so be sure to read that part.

2. Setup the [EMCECS Helm Repository](https://github.com/EMCECS/charts).

  ```bash
  $ helm repo add ecs https://emcecs.github.io/charts
  $ helm repo update
  ```

3. Install the ObjectScale manager. This allows you to create and manage object stores.

  ```bash
  $ helm install obj-mgr1 ecs/objectscale-manager
  NAME:   obj-mgr1
  ```

There are [configuration options](../ecs-flex-operator#configuration) you can peruse later at your heart's delight.

4. Install an object store 

  ```bash
  $ helm install objectstore1 ecs/ecs-cluster 
  NAME:   objectstore1
  ...
  ```

There are [configuration options](#configuration) for that, too.

5. Check the notes printed after the install. They offer a helpful guide to get access to your cluster via S3.

## Configuration



## <a name="sc-setup"></a>Private Kubernetes Storage Class Setup

For private Kubernetes deployments, if a dynamic storage class does not already exist, it must be setup. Both [Minikube](https://kubernetes.io/docs/setup/minikube/) and [Docker for Desktop](https://www.docker.com/products/docker-desktop) Kubernetes distributions include such a storage class by default. For convenience, we've added instructions for VMware vSphere virtualised clusters, and Dell EMC VxFlex OS supported options.

### VMware vSphere Storage Class Setup

VMware vSphere supports a private storage class for dynamic creation and attachment of VMDK volumes. This driver is distributed with Kubernetes, so simply create a storage-class as follows:
```bash
$ kubectl apply -f - <<-EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: vsphere
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/vsphere-volume
parameters:
  diskformat: zeroedthick
  fstype: xfs
EOF
```

### Dell EMC VxFlex OS

When deploying on a [Dell EMC VxFlex-based system](https://www.dellemc.com/en-us/solutions/software-defined/vxflex-ready-nodes.htm), you can install a storage class using the available [VxFlex OS CSI driver Helm chart](https://github.com/VxFlex-OS/charts).

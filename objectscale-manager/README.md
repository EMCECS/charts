# Dell EMC Elastic Cloud Storage (ECS) Flex Operator Helm Chart

This Helm chart deploys an [operator](https://coreos.com/operators/) capable of deploying and upgrading ECS S3-compatible object storage systems.

## Table of Contents

* [Description](#description)
* [Requirements](#requirements)
* [Quick Start](#quick-start)
* [Configuration](#configuration)
  * [Namespace Access](#namespace-access)
  * [Private Docker Registry](#private-docker-registry)
  * [Log Aggregation](#log-aggregation)
    * [Platform-level logging](#platform-level-logging)
    * [Configuring a log receiver](#configuring-a-log-receiver)
* [Private Kubernetes Storage Class Setup](#sc-setup)

## Description

The ECS Flex Operator includes a pair of Kubernetes deployments that manage Zookeeper and ECS Clusters. The operator will create a `Custom Resource Definition` for each managed cluster type.

```bash
$ kubectl get zookeeper-cluster
NAME                   CREATED AT
my-cluster-zookeeper   14h

$ kubectl get ecs-cluster
NAME          CREATED AT
my-cluster    14h
```

## Requirements

* A [Helm](https://helm.sh) installation with access to install to one or more namespaces.
* A Kubernetes Storage Class capable of dynamically creating `ReadWriteOnce` (`RWO`) volumes. This is available in many public Kubernetes services, such as AWS EKS and Google GKE. For more information see the [storage class section](#sc-setup) below.

## Quick Start

1. First, [install and setup Helm](https://docs.helm.sh/using_helm/#quickstart).  *_Note:_* you'll likely need to setup role-based access controls for Helm to have rights to install packages, so be sure to read that part.

2. Setup the [EMCECS Helm Repository](https://github.com/EMCECS/charts).

```bash
$ helm repo add ecs https://emcecs.github.io/charts
$ helm repo update
```

3. Install the ECS Flex Operator. This allows you to create and manage ECS clusters.

via Helm 2:

```bash
$ helm install --name ecs-flex ecs/ecs-flex-operator
NAME:   ecs-flex
...
```

or via Helm 3:

```bash
$ helm install ecs-flex ecs/ecs-flex-operator
NAME:   ecs-flex
...
```

There are [configuration options](#configuration) you can peruse later at your heart's delight.

4. Install an ECS Cluster.

```bash
$ helm install --name my-cluster ecs/ecs-cluster
NAME:   my-cluster
...
```

or via Helm 3:

```bash
$ helm3 install my-cluster ecs/ecs-cluster
NAME:   my-cluster
...
```

There are [configuration options](../ecs-cluster#configuration) for that, too.

5. Check the notes printed after the install. They offer a helpful guide to get access to your cluster via S3.

## Configuration

### Namespace Access

The ECS Flex Operator can be configured to manage a single namespace within a Kubernetes cluster, or all namespaces. To configure a watch on its own namespace, simply set the `global.watchAllNamespaces` setting:

```bash
$ helm install ecs-flex \
    --set global.watchAllNamespaces=false \
    ecs/ecs-flex-operator
```

To use the operator with any namespace on the Kubernetes cluster, you can retain the default configuration, which is to set the `global.watchAllNamespaces` setting to true.

### Private Docker Registry

While the ECS Flex container images are hosted publicly, the ECS Flex operator also supports configuration of a private Docker registry for offline Kubernetes clusters or those that do not have access to public registries. To configure a private registry:

1. Download the ECS Flex container image bundle from [support.emc.com] and upload the images to your private registry.

_*TODO: Add download link once available*_

2. Add a Kubernetes secret for the [private Docker registry](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)

```bash
$ kubectl create secret docker-registry ecs-flex-registry \
    --docker-username=<DOCKER_USERNAME> \
    --docker-password=<DOCKER_PASSWORD> \
    --docker-email=<DOCKER_EMAIL>
```

3. Set the registry secret and location in the Helm chart installations  via Helm:

```bash
helm install \
    --set global.registry=<REGISTRY ADDRESS> \
    --set global.registrySecret=<SECRET_NAME> \
    ecs/ecs-flex-operator
```

### Log Aggregation

The ECS Flex operator supports the configuration of either a platform-level logging solution, such as [Google Stackdriver](https://cloud.google.com/stackdriver/) or a [custom Fluentd setup](https://docs.fluentd.org/v0.12/articles/kubernetes-fluentd), _or_ a configured log receiver.

#### Platform-level logging

#### Configuring a log receiver

The ECS Flex operator will automatically configure logging sidecar containers to forward logs to either a Syslog or Elasticsearch based log receiver. These options can be set via Helm:

*To connect to a Elasticsearch-based receiver:*

```bash
$ helm install --name ecs-flex \
    --set logReceiver.type=Elasticsearch \
    --set logReceiver.host=elastic \
    --set logReceiver.port=9200 \
    --set logReceiver.protocol=http \
    ecs/ecs-flex-operator
```

*To connect to a Syslog-based receiver:*

```bash
$ helm install --name ecs-flex \
    --set logReceiver.type=Syslog \
    --set logReceiver.host=rsyslog \
    --set logReceiver.port=514 \
    --set logReceiver.protocol=tcp \
    ecs/ecs-flex-operator
```

The ECS Flex operator can also create a Syslog-based receiver in a Kubernetes deployment:

```bash
$ helm install --name ecs-flex --set logReceiver.create=true ecs/ecs-flex-operator
```

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
    storageclass.kubernetes.io/is-default-class: true
provisioner: kubernetes.io/vsphere-volume
parameters:
  diskformat: zeroedthick
  fstype: xfs
EOF
```

### Dell EMC VxFlex OS

When deploying on a [Dell EMC VxFlex-based system](https://www.dellemc.com/en-us/solutions/software-defined/vxflex-ready-nodes.htm), you can install a storage class using the available [VxFlex OS CSI driver Helm chart](https://github.com/VxFlex-OS/charts).

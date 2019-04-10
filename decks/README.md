# Dell EMC Common Kubernetes Support

This Helm chart deploys a controller [decks] capable of watching Application Resources and Kubernetes Events. Its purpose is take a gateway request, verify the availability of a gateway, create the resource, and watch for updates to the gateway resource.

## Table of Contents

* [Description](#description)
* [Requirements](#requirements)
* [Quick Start](#quick-start)
* [Configuration](#configuration)
  * [Namespace Access](#namespace-access)
  * [Private Docker Registry](#private-docker-registry)

## Description

DECKS includes a Kubernetes deployment that manage DECKS controller.

```bash
$ kubectl get deployment decks
NAME   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
decks   1         1         1            1           70m
```

## Requirements

* A [Helm](https://helm.sh) installation with access to install to one or more namespaces.

## Quick Start

1. First, [install and setup Helm](https://docs.helm.sh/using_helm/#quickstart).  *_Note:_* you'll likely need to setup role-based access controls for Helm to have rights to install packages, so be sure to read that part.

2. Setup the [EMCECS Helm Repository](https://github.com/EMCECS/charts).

```bash
$ helm repo add ecs https://emcecs.github.io/charts
$ helm repo update
```

3. Install the DECKS. This allows you to start watching the Kubernetes Application resources as well as Kubernetes Events.

```bash
$ helm install --name decks ecs/decks
NAME:  decks
...
```

There are [configuration options](#configuration) you can peruse later at your heart's delight.

## Configuration

### Namespace Access

DECKS can be configured to manage a single namespace within a Kubernetes cluster, or all namespaces. To configure a specific namespace, simply set the `global.watchNamespace` setting:

```bash
$ helm install --name decks \
    --set global.watchNamespace=my-namespace \
    ecs/decks
```

To use the decks with any namespace on the Kubernetes cluster, you can retain the default configuration, which is to set the `global.watchNamespace` setting to an empty string (`""`).

### Private Docker Registry

While the ECS Flex container images are hosted publicly, DECKS also supports configuration of a private Docker registry for offline Kubernetes clusters or those that do not have access to public registries. To configure a private registry:

1. Download the DECKS container image from [support.emc.com] and upload the images to your private registry.

_*TODO: Add download link once available*_

2. Add a Kubernetes secret for the [private Docker registry](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)

```bash
$ kubectl create secret docker-registry decks-registry \
    --docker-username=<DOCKER_USERNAME> \
    --docker-password=<DOCKER_PASSWORD> \
    --docker-email=<DOCKER_EMAIL>
```

3. Set the registry secret and location in the Helm chart installations  via Helm:

```bash
helm install \
    --set global.registry=<REGISTRY ADDRESS> \
    --set global.registrySecret=<SECRET_NAME> \
    ecs/decks
```

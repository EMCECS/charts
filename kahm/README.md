# Kubernetes Application Health Management Helm Chart

This Helm chart deploys a controller [kahm] capable of watching Application Resources and Kubernetes Events.  It stores the events in a persistent data store and send those events to various adaptors (SRS Gateway, SNMP, SMTP , Slack etc.) to report the events to customers so that they can manage the health of the clusters in a timely manner.

## Table of Contents

* [Description](#description)
* [Requirements](#requirements)
* [Quick Start](#quick-start)
* [Configuration](#configuration)
  * [Namespace Access](#namespace-access)
  * [Private Docker Registry](#private-docker-registry)

## Description

The KAHM includes a Kubernetes deployment that manage KAHM controller.

```bash
$ kubectl get deployment kahm
NAME   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
kahm   1         1         1            1           70m
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

3. Install the KAHM. This allows you to start watching the Kubernetes Application resources as well as Kubernetes Events.

```bash
$ helm install --name kahm ecs/kahm
NAME:  kahm 
...
```

There are [configuration options](#configuration) you can peruse later at your heart's delight.

## Configuration

### Namespace Access

The KAHM can be configured to manage a single namespace within a Kubernetes cluster, or all namespaces. To configure to watch its own namespace, simply set the `global.watchAllNamespaces` setting:

```bash
$ helm install --name kahm \
    --set global.watchAllNamespaces=false \
    ecs/kahm
```

To use the kahm to watch all namespaces on the Kubernetes cluster, you can retain the default configuration, which is to set the `global.watchAllNamespaces` setting to true.
```bash
$ helm install --name kahm \
    --set global.watchAllNamespaces=true \
    ecs/kahm
```

### Private Docker Registry

While the ECS Flex container images are hosted publicly, KAHM also supports configuration of a private Docker registry for offline Kubernetes clusters or those that do not have access to public registries. To configure a private registry:

1. Download the KAHM container image from [support.emc.com] and upload the images to your private registry.

_*TODO: Add download link once available*_

2. Add a Kubernetes secret for the [private Docker registry](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)

```bash
$ kubectl create secret docker-registry kahm-registry \
    --docker-username=<DOCKER_USERNAME> \
    --docker-password=<DOCKER_PASSWORD> \
    --docker-email=<DOCKER_EMAIL>
```

3. Set the registry secret and location in the Helm chart installations  via Helm:

```bash
helm install \
    --set global.registry=<REGISTRY ADDRESS> \
    --set global.registrySecret=<SECRET_NAME> \
    ecs/kahm
```

4. Verify whether KAHM is installed successfully and working as expected. The "helm test <release-name>" instatiate a test-app which instantaite sample application object, sample event rules, create mock Notifiers and generate sample events to verify KAHM functionality as a black box. "kubectl logs <release-name>-kahm-test should show that the sample Notifiers have received the sample events.

```bash
helm test <release-name>
```

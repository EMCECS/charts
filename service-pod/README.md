#Dell EMC Service Pod Helm Chart

This Helm chart deploys a service pod capable of collecting logs, provides remote-access to the cluster, and allow easy access to the  debugging tools to debug the issues.

## Table of Contents

* [Description](#description)
* [Confirming Remote Access Functionality](#confirming Remote Access Functionality)
* [Special Consideration for Deploying on Minikube](#Special Consideration for Deploying on Minikube)
* [Requirements](#requirements)
* [Quick Start](#quick-start)
* [Configuration](#configuration)
* [Private Docker Registry](#private-docker-registry)

## Description

The Dell EMC service pod is a k8s pod with the following capabilities:
- login and analyze the k8s cluster environment
- tools and scripts to triage the k8s cluster 
- collect logs from the deployed pods
- allow remote access via ssh

For security, the service pod can be configured with a customizable user/group/password credentials for SSH access. The user/group/password credentials can be configured via a Kubernetes secret that contains the user/group/password. Note that the name of the credentials secret needs to match the name of the credentials secret that is used in the service pod deployment's secret mount.

## Confirming Remote Access Functionality
1. Find the external IP(s) that is(are) assigned to the remote access service:
```
kubectl get svc | grep "NAME\|service-pod"
```
2. Using the first external IP from the previous command, SSH into the service pod:
```
ssh root@<service-pod-external-ip>
(Password: ChangeMe)
```
e.g.
```
ssh root@10.11.12.13
(Password: ChangeMe)
```

## Special Consideration for Deploying on Minikube
When deploying on Minikube, you will need to install the MetalLB software loadbalancer, so that the service-pod will get an external IP for access from outside the cluster. Installation of MetalLB is documented in the ["Install MetalLB Software Load Balancer" section of the FLEX on Minikube wiki](https://asdwiki.isus.emc.com:8443/display/ECS/How+to+deploy+ECS+Flex+on+Minikube#HowtodeployECSFlexonMinikube-OPTIONAL:InstallMetalLBSoftwareLoadBalancer).

Note that for external access, the ConfigMap that is used to configure Minikube will need to include a pool of routed, public IPs (IPs that are routed to the Minikube host), so that Minikube will assign one of the routed, public IPs to the remote access service.


## Requirements

* A [Helm](https://helm.sh) installation with access to install to one or more namespaces.

## Quick Start

1. First, [install and setup Helm](https://docs.helm.sh/using_helm/#quickstart).  *_Note:_* you'll likely need to setup role-based access controls for Helm to have rights to install packages, so be sure to read that part.

2. Setup the [EMCECS Helm Repository](https://github.com/EMCECS/charts).

```bash
$ helm repo add ecs https://emcecs.github.io/charts
$ helm repo update
```

3. Install the service-pod. This allows you to create a service-pod for debugging the issues, collect logs and to provide remote-access. It is mandatory to provide a product name as a commond line option. 
```bash
$ helm install --name objectscale-service-pod ecs/service-pod --set product=objectscale
NAME:  objectscale-service-pod
...
```

There are [configuration options](#configuration) you can peruse later at your heart's delight.

## Configuration

### Private Docker Registry

While the service-pod container image is hosted publicly, the service-pod also supports configuration of a private Docker registry for offline Kubernetes clusters or those that do not have access to public registries. To configure a private registry:

1. Download the ice-pod container image bundle from [support.emc.com] and upload the images to your private registry.

_*TODO: Add download link once available*_

2. Add a Kubernetes secret for the [private Docker registry](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)

```bash
$ kubectl create secret docker-registry service-pod-registry \
    --docker-username=<DOCKER_USERNAME> \
    --docker-password=<DOCKER_PASSWORD> \
    --docker-email=<DOCKER_EMAIL>
```

3. Set the registry secret and location in the Helm chart installations  via Helm:

```bash
helm install \
    --set global.registry=<REGISTRY ADDRESS> \
    --set global.registrySecret=<SECRET_NAME> \
    ecs/service-pod
```

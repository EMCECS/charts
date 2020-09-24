# Helm Chart for Deploying Dell EMC SupportAssist Embedded Services Enabler
This chart allows the user to deploy a Dell EMC SupportAssist embedded services enabler in the Kubernetes cluster for a product.
 
## Table of Contents

* [Description](#description)
* [Requirements](#requirements)
* [Quick Start](#quick-start)

## Description

This Helm chart deploys:
1. A k8s statefulset pod for SupportAssist ESE for the product:
   `supportassist-objectscale-0`
2. A persistent volume to store logs and secure keys
3. Future changes will add in the supportassist custom resource, secrets etc...

## Requirements

* A [Helm 3.0](https://helm.sh) installation with access to install to one or more namespaces.
* Access to https://github.com/EMCECS/charts
* Access to docker registries:
    * https://hub.docker.com/objectscale
* Dell EMC Connectivity servers:
    * Direct firewalled access to https://esrs3*.com servers or
    * Local SRS gateways already firewalled to Dell EMC Connectivity servers:

## Quick Start

1. First, [install and setup Helm](https://docs.helm.sh/using_helm/#quickstart).

2. Using your github token add the helm chart repo

    ```
    $ helm repo add objectscale https://<yourgihubtoken>@raw.githubusercontent.com/emcecs/charts/master/docs
    $ helm repo update
    ```

3. Install the Dell EMC Embedded support enables (ESE) for the product: 
    - for example  **objectscale** these are the **required** parameters:
    - **Note:** for internal testing **only**!! 
    ```
    $ helm install objs-sa objectscale/supportassist --set product=objectscale,productVersion=0.51.0,siteID=45454545,accessKey=4F56ADB8,pin=5555,gateways[0].hostname="10.11.12.13",gateways[0].port=9443,gateways[0].priority=20
    ```

4. Verify the pod and service is available:
    ```bash
    $ kubectl get pod,svc -l release=supportassist-objectscale

    NAME                              READY   STATUS    RESTARTS   AGE
    pod/supportassist-objectscale-0   1/1     Running   0          15h

    NAME                                         TYPE           CLUSTER-IP   EXTERNAL-IP    PORT(S)                         AGE
    service/supportassist-objectscale            LoadBalancer   10.96.1.89   10.240.124.9   9447:31526/TCP,8080:32740/TCP   15h
    service/supportassist-objectscale-headless   ClusterIP      None         <none>         9447/TCP,8080/TCP               15h
    ```
5. For internal testing Use Postman to test SupportAssist ESE RESTAPIs

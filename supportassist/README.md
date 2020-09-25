# Helm Chart for Deploying Dell EMC SupportAssist Embedded Services Enabler
This chart allows the user to deploy a Dell EMC SupportAssist embedded services enabler in the Kubernetes cluster for a product.
 
## Table of Contents

* [Description](#description)
* [Requirements](#requirements)
* [Quick Start](#quick-start)
* [Configuration](#configuration)

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

## Configuration

Customer contact information can be supplied thru an array or via a file using the following examples:
###  customercontactsfile
it is a location of the product customer contact yaml file. The file must be in yaml format and follow the template below.If the file is in your current directory, you can simply provide the name of the yaml file. If the file is in another location, you need to provide the pathname of the file.
#### Customer contacts file template:
```yaml
contacts:
  - contactorder: 1
    firstname: XXX
    lastname: XXX
    phonenumber: "+1 (555) 555-7746"
    emailaddress: test@dell.com
    timezoneoffset: -06:00
    prefcontact: phone
    prefcontacttime: 11:00AM - 1:00AM
    preflanguage: En
  - contactorder: 2
    firstname: XXX
    lastname: XXX
    phonenumber: "+1 (312) 555-7748"
    emailaddress: test@dell.com
    timezoneoffset: -06:00vim
    prefcontact: email
    prefcontacttime: 1:00PM - 3:00AM
    preflanguage: En
```
Example helm install command line setting:
```
--set-file customercontactsfile=objectscale-customercontact.yaml
--set-file customercontactsfile=/home/xxx/objectscale-customercontact.yaml
--set-file customercontactsfile=../../../xxx/objectscale-customercontact.yaml
```
###  contacts
```    
$ helm install objs-sa objectscale/supportassist --set product=contacts[0].contactorder=1,contacts[0].firstname=XXX,contacts[0].lastname=XXX,contacts[1].contactorder=2,contacts[1].lastname=XXX,contacts[1].firstname=XXX
```
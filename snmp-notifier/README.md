# Helm Chart for Deploying Dell EMC SNMP Notifier
This chart allows the user to deploy a Dell EMC SNMP Notifier in the Kubernetes cluster for a product. The SNMP Notifier send TRAPs to the configured SNMP manager.

## Table of Contents

* [Description](#description)
* [Requirements](#requirements)
* [Quick Start](#quick-start)
* [Configuration](#configuration)

## Description

This Helm chart deploys:
1. A k8s deployment  SNMP notifier pod for the product:
   `<release-name>-<product>-snmp-notifier-xxx`
2. A Notifier CR with GRPC information for KAHM to connect to send events
3. A secret to store the SNMP manager configration information
4. Application resource
5. Application Configmap to define rules to send TEST TRAPs
6. SA, Role and Role bindings for Notifier Pod

## Requirements

* A [Helm 3.0](https://helm.sh) installation with access to install to one or more namespaces.
* Access to https://github.com/EMCECS/charts
* Access to docker registries:
    * https://hub.docker.com/objectscale
* A SNMP manager must be installed in order for SNMP agent to connect and deliver the SNMP traps. The SNMP manager must be configured with the username, authetication parameters and with the same engineID which SNMP notifer is configured.

## Quick Start

1. First, [install and setup Helm](https://docs.helm.sh/using_helm/#quickstart).

2. Using your github token add the helm chart repo

    ```
    $ helm repo add objectscale https://<yourgihubtoken>@raw.githubusercontent.com/emcecs/charts/master/docs
    $ helm repo update
    ```

3. Install the Dell EMC SNMP Notifier for the product: 
    - **product** and **host** are the **required** parameters
    ```
    $ helm install snmp-notifier objectscale/snmp-notifier --set product=objectscale,snmpServer.host="10.11.12.13"
    ```
    Note: by default v2c SNMP notifier will be confgured with "public" community string. Please see the configuration section for v3 configuration.

4. Verify the pod and service is available:
    ```bash
    $ kubectl get pod,svc -l release=snmp-notifier

    NAME                                                           READY   STATUS    RESTARTS   AGE
    pod/snmp-notifier-objectscale-snmp-notifier-66696cc888-cn44k   1/1     Running   1          42h
    
    NAME                                              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)     AGE
    service/snmp-notifier-objectscale-snmp-notifier   ClusterIP   10.96.244.12   <none>        50051/TCP   42h
    ```

## Configuration

### configure v3 SNMP notifier to send v3 SNMP traps
In order to setup SNMP v3 notifier, the following configuration parameters are mandatory:

 1. version
 2. username
 3. securityLevel
 4. engineID

If securityLevel is "auth", then the following parameters are mandatory in addtion to the above
 1. authPass
 2. authProtocol

If securityLevel is "authpriv", then the following parameters are mandatory in addtion to the above
 1. privPass
 2. privProtocol

    ```
    $ helm install snmp-notifier objectscale/snmp-notifier --set product=objectscale,snmpServer.host="10.11.12.13",snmpServer.version=v3, snmpServer.username="xxx",snmpServer.securityLevel="none", snmpServer.EngineID="<Hexa decimal string>"
   
    $ helm install snmp-notifier objectscale/snmp-notifier --set product=objectscale,snmpServer.host="10.11.12.13",snmpServer.version=v3, snmpServer.username="xxx",snmpServer.securityLevel="auth", snmpServer.authPass=yyyy,snmpServer.authProtocol=MD5,snmpServer.engineID="2345678910FFEEED"

    $ helm install snmp-notifier objectscale/snmp-notifier --set product=objectscale,snmpServer.host="10.11.12.13",snmpServer.version=v3, snmpServer.username="xxx",snmpServer.securityLevel="authpriv", snmpServer.authPass=yyyy,snmpServer.authProtocol=MD5,privPass=zzzz,privProtocol=SHA,snmpServer.engineID="2345678910FFEEED"
    ```

## TEST-TRAPS
In order to test SNMP TRAPs, a test-trap event need to generate in the same namepace where the snmp-notifier is configured. The following command need to execute in order to send SNMP TEST TRAP.

 ```
 apiVersion: v1
 involvedObject:
   apiVersion: app.k8s.io/v1beta1
   kind: Application
   name: <helm-release-name>-<productName>-snmp-notifier
   namespace: default
 kind: Event
 message: test SNMP trap
 metadata:
   generateName: testtrap1
   labels:
      SymptomID: "TEST-TRAP"
 reason: TestTrap
 source:
   component: snmp-testtrap
 type: Normal

 Example with release-name: snmp-notifier and product: objectscale

    cat <<EOF | kubectl create -f -
> apiVersion: v1
> involvedObject:
>   apiVersion: app.k8s.io/v1beta1
>   kind: Application
>   name: snmp-notifier-objectscale-snmp-notifier
>   namespace: default
> kind: Event
> message: test SNMP trap
> metadata:
>   generateName: testtrap1
>   labels:
>      SymptomID: "TEST-TRAP"
> reason: TestTrap
> source:
>   component: snmp-testtrap
> type: Normal
>
> EOF

 ```

# Dell EMC Common Kubernetes Services

This Helm chart deploys a controller [decks] capable of managing Dell EMC SRS Gateways, Dell EMC Licenses, Remote access, Telemetry upload.

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
decks   1         1         1            1          70m
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

3. Install DECKS. This allows you to start manage Dell EMC SRS gateways and licenses

```bash
$ helm install --name decks ecs/decks
NAME:  decks
...
```

There are [configuration options](#configuration) you can peruse later at your heart's delight.

## Configuration

### Namespace Access

DECKS can be configured to manage a single namespace within a Kubernetes cluster, or all namespaces. To watch its own namespace, simply set the `global.watchAllNamespaces` setting:

```bash
$ helm install decks --set global.watchAllNamespaces=false
```

To use the decks with any namespace on the Kubernetes cluster, you can retain the default configuration, which is to set the `global.watchAllNamespaces` setting to true.

### Private Docker Registry

While the container images are hosted publicly, DECKS also supports configuration of a private Docker registry for offline Kubernetes clusters or those that do not have access to public registries. To configure a private registry:

1. Download the DECKS container image from [support.emc.com] and upload the images to your private registry.

_*TODO: Add download link once available*_

2. Add a Kubernetes secret for the [private Docker registry](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)

   ```bash
   kubectl create secret docker-registry decks-registry \
    --docker-username=<DOCKER_USERNAME> \
    --docker-password=<DOCKER_PASSWORD> \
    --docker-email=<DOCKER_EMAIL>
   ```

3. Set the registry secret and location in the Helm chart installations  via Helm:

   ```bash
   helm install --set global.registry=<REGISTRY ADDRESS> \
    --set global.registrySecret=<SECRET_NAME> \
    ecs/decks
   ```
4. Verify whether DECKS is installed successfully and working as expected by using the "helm test <release-name>" command.
   - Use "helm upgrade" on the deployment by specifying a valid SRS gateway hostname, login and product name
   - Then when a "helm test" is run it will: 
     - Creates a decks test-app application/pod
     - Registers an SRS gateway. The test SRSGateway IP, Port, Login, and Product   to be tested are configurable. 
     - Runs a call home test event.
     - Verifies an external IP is generated for the remote access pod
     - Verifies ssh connectivity to the remote access pod
       `kubectl logs <release-name>-deck-test` should show the testapp output logs.
   - This is the *helm upgrade* to use to set the srs gateway params for the test:
    ```bash
       helm upgrade decks ecs/decks --set helmTestConfig.srsGateway.hostname="10.11.12.13" --set helmTestConfig.srsGateway.login=testuser123@example.com:MyFavePassword --set helmTestConfig.srsGateway.product=OBJECTSCALE

       helm test <release-name>

    ```

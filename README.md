# Dell EMC ObjectScale Helm Charts Sources

This repository provides all Dell EMC ObjectScale related sources for [Kubernetes](http://kubernetes.io), formatted as [Helm](https://helm.sh) packages.

To add this repository to your local Helm installation:

> *_NOTE: Currently, this is a private repository, so use the private repo instructions below. Public repo options will be available once we go public._*

This is the chart source repo, binaries were migrated to [EMCECS/charts-bin repo](https://github.com/EMCECS/charts-bin) 

## Adding the ECS Repository

```bash
$ helm repo add ecs https://emcecs.github.io/charts-bin
$ helm repo update
```
## Available Charts

* [ObjectScale Manager](objectscale-manager)
* [ECS Cluster](ecs-cluster)
* [Atlas Operator](atlas-operator)
* [Zookeeper Operator](zookeeper-operator)
* [Mongoose Load Testing Tool](mongoose)
* [DECKS](decks)
* [KAHM](kahm)
* [SRS Gateway](srs-gateway)
* [DellEMC license](dellemc-license)
* [IAM](objectscale-iam)
* [DCM](objectscale-dcm)

## Adding private Helm repository and Docker registries

In this development phase, both the Helm repository and referenced Docker registries are private. Before installing charts from this repository, you must add private credentials to Helm and Kubernetes for Github and Docker Hub, respectively.

### Add Private Github-Hosted Helm Repository

1. Create an authentication token in Github with read access to the charts repository.

  - Navigate to your account [personal access tokens](https://github.com/settings/tokens)
  - Click "Create new token" at the top right. This will select all permissions for repositories.
  - Add a token description
  - Select the "repo" permissions checkbox
  - Copy the token for use in the next step

2. Create the repository using your token:

```bash
$ helm repo add ecs \
  "https://MY_PRIVATE_TOKEN@raw.githubusercontent.com/emcecs/charts-bin/master/docs"
$ helm repo update
```

3. Ensure that you can see the ECS charts

```bash
$ helm search ecs
NAME                          	CHART VERSION	APP VERSION	DESCRIPTION                                       
ecs/atlas-operator            	0.32.0       	0.14.0     	Atlas operator deploys a custom resource for an...
ecs/bookkeeper-operator       	0.1.3        	0.1.3      	Bookkeeper Operator Helm chart for Kubernetes     
ecs/common-lib                	0.77.0       	0.77.0     	A Helm chart for Kubernetes                       
ecs/dcm                       	0.74.0       	0.74.0     	A Helm chart for Dell EMC DCM                     
ecs/decks                     	2.77.0       	2.77.0     	A Helm chart for Dell EMC Common Kubernetes Ser...
ecs/decks-support-store       	2.77.0       	2.77.0     	A Helm chart for Dell EMC Common Kubernetes Ser...
ecs/dellemc-license           	2.77.0       	2.77.0     	A Helm chart for applying a Dell EMC License fo...
ecs/dks-testapp               	1.2.0        	1.2.0      	A Helm chart for DKS (DECKS, KAHM, and SRSGatew...
ecs/ecs-cluster               	0.77.0       	0.77.0     	Dell EMC ObjectScale is highly scalable, and hi...
ecs/federation                	0.77.0       	0.77.0     	A Helm chart for Dell EMC Federation Service      
ecs/fio-test                  	0.28.2       	3.14.1     	A Helm chart for Kubernetes Applications Health...
ecs/helm-controller           	0.77.0       	0.77.0     	helm-controller runs inside the cluster and act...
ecs/iam                       	0.65.0       	0.65.0     	A Helm chart for Dell EMC IAM                     
ecs/influxdb-operator         	0.77.0       	0.77.0     	InfluxDB Operator deploys operator pod which is...
ecs/kahm                      	2.77.0       	2.77.0     	A Helm chart for Kubernetes Applications Health...
ecs/logging-injector          	0.77.0       	0.77.0     	Rsyslog client sidecar injector                   
ecs/mongoose                  	0.1.3        	4.1.1      	Mongoose is a horizontally scalable and configu...
ecs/objectscale-dcm           	0.77.0       	0.77.0     	A Helm chart for Dell EMC DCM                     
ecs/objectscale-gateway       	0.77.0       	0.77.0     	A Helm chart for Dell EMC Objectscale Gateway     
ecs/objectscale-graphql       	0.77.0       	0.77.0     	A Helm chart for Kubernetes                       
ecs/objectscale-iam           	0.77.0       	0.77.0     	A Helm chart for Dell EMC IAM                     
ecs/objectscale-manager       	0.77.0       	0.77.0     	Dell EMC ObjectScale is highly scalable, and hi...
ecs/objectscale-portal        	0.77.0       	0.77.0     	ObjectScale Portal                                
ecs/objectscale-vsphere       	0.77.0       	0.77.0     	ObjectScale VMware vSphere Plugin                 
ecs/pravega-operator          	0.5.2        	0.5.2      	Pravega Operator Helm chart for Kubernetes        
ecs/service-pod               	2.77.0       	2.77.0     	A Helm chart for Dell EMC Service Pod             
ecs/sonobuoy                  	0.16.6       	0.16.6     	A Helm chart for sonobuoy                         
ecs/srs-gateway               	1.2.0        	1.2.0      	A Helm chart for Dell EMC SRS Gateway Custom Re...
ecs/statefuldaemonset-operator	0.77.0       	0.77.0     	StatefulDaemonSet operator deploys operator pod...
ecs/supportassist             	2.77.0       	2.77.0     	Helm chart for Dell SupportAssist ESE             
ecs/zookeeper-operator        	0.28.0       	0.28.0     	Zookeeper operator deploys a custom resource fo...
```

### Add Private Docker Registry for your Kubernetes Cluster

1. If you do not currently have a [Docker Hub](https://hub.docker.com) account, create one.

2. Ensure that you have access to the private repositories hosted in the EMCCorp Docker account. If you are unsure, please contact someone on the ECS Flex team for access.

3. Add a Kubernetes secret for [private Docker registry](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)

```bash
$ kubectl create secret docker-registry ecs-flex-registry \
  --docker-username=<DOCKER_USERNAME> \
  --docker-password=<DOCKER_PASSWORD> \
  --docker-email=<DOCKER_EMAIL>
```

You can then set it in the Helm chart installations (`objectscale-manager` and `ecs-cluster`) with a Helm setting: `--set global.registrySecret=<SECRET_NAME>`.  If you set the `registrySecret` setting in the ecs-flex-operator, it will be assumed in any operator created ECS clusters; however, the parameter can still be set in an `ecs-cluster` release.

# Dell EMC ObjectScale Helm Charts

This repository provides all Dell EMC ObjectScale related packages for [Kubernetes](http://kubernetes.io), formatted as [Helm](https://helm.sh) packages.

To add this repository to your local Helm installation:

> *_NOTE: Currently, this is a private repository, so use the private repo instructions below. Public repo options will be available once we go public._*

This is the chart source repo, binaries were migrated to [EMCECS/charts-bin repo](https://github.com/EMCECS/charts-bin) 

## Adding the ECS Repository

```bash
$ helm repo add ecs https://emcecs.github.io/charts-bin
$ helm repo update
```
## Available Charts

* [ECS Flex Operator](ecs-flex-operator)
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

In this development phase, both the Helm repostory and referenced Docker registries are private. Before installing charts from this repository, you must add private credentials to Helm and Kubernetes for Github and Docker Hub, respectively.

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
NAME                  	CHART VERSION	APP VERSION	DESCRIPTION                                                 
ecs/ecs-cluster       	0.1.6        	0.1.6      	Dell EMC Elastic Cloud Storage is highly scalable, and hi...
ecs/ecs-flex-operator 	0.1.6        	0.1.6      	Dell EMC Elastic Cloud Storage is highly scalable, and hi...
ecs/decks             	0.2.0        	0.2.0      	A Helm chart for Dell EMC Common Kubernetes Services        
ecs/kahm              	0.2.0        	0.2.0      	A Helm chart for Kubernetes Applications Health Management  
ecs/mongoose          	0.1.3        	4.1.1      	Mongoose is a horizontally scalable and configurable S3 p...
ecs/srs-gateway       	0.2.0        	0.2.0      	A Helm chart for Dell EMC SRS Gateway Custom Resource Sup...
ecs/zookeeper-operator	0.1.6        	0.2.0      	Zookeeper operator deploys a custom resource for a zookee...
ecs/dellemc-license     0.6.0   	0.6.0           A Helm chart to install a Dell EMC License for a product	
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

You can then set it in the Helm chart installations (`ecs-flex-operator` and `ecs-cluster`) with a Helm setting: `--set global.registrySecret=<SECRET_NAME>`.  If you set the `registrySecret` setting in the ecs-flex-operator, it will be assumed in any operator created ECS clusters; however, the parameter can still be set in an `ecs-cluster` release.

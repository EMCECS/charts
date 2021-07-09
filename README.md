# Dell EMC ObjectScale Helm Charts Sources

This repository provides all Dell EMC ObjectScale related sources for [Kubernetes](http://kubernetes.io), formatted as [Helm](https://helm.sh) packages.

To add this repository to your local Helm installation:

This is the chart source repo, binaries were migrated to [EMCECS/charts-bin repo](https://github.com/EMCECS/charts-bin) 

## Adding the ObjectScale Repository

Add the repository to helm:

Master Branch:
```bash
$ helm repo add objectscale https://emcecs.github.io/charts-bin
$ helm repo update
```

Specific version:
```bash
$ helm repo add objectscale https://raw.githubusercontent.com/emcecs/charts-bin/<version tag>/docs
$ helm repo update
```

Ensure that you can see the ObjectScale charts:

```bash
$ helm search repo objectscale
NAME                          	CHART VERSION	APP VERSION	DESCRIPTION                                       
objectscale/atlas-operator            	0.32.0       	0.14.0     	Atlas operator deploys a custom resource for an...
objectscale/bookkeeper-operator       	0.1.3        	0.1.3      	Bookkeeper Operator Helm chart for Kubernetes     
objectscale/common-lib                	0.77.0       	0.77.0     	A Helm chart for Kubernetes                       
objectscale/dcm                       	0.74.0       	0.74.0     	A Helm chart for Dell EMC DCM                     
objectscale/decks                     	2.77.0       	2.77.0     	A Helm chart for Dell EMC Common Kubernetes Ser...
objectscale/decks-support-store       	2.77.0       	2.77.0     	A Helm chart for Dell EMC Common Kubernetes Ser...
objectscale/dellemc-license           	2.77.0       	2.77.0     	A Helm chart for applying a Dell EMC License fo...
objectscale/dks-testapp               	1.2.0        	1.2.0      	A Helm chart for DKS (DECKS, KAHM, and SRSGatew...
objectscale/ecs-cluster               	0.77.0       	0.77.0     	Dell EMC ObjectScale is highly scalable, and hi...
objectscale/federation                	0.77.0       	0.77.0     	A Helm chart for Dell EMC Federation Service      
objectscale/fio-test                  	0.28.2       	3.14.1     	A Helm chart for Kubernetes Applications Health...
objectscale/helm-controller           	0.77.0       	0.77.0     	helm-controller runs inside the cluster and act...
objectscale/iam                       	0.65.0       	0.65.0     	A Helm chart for Dell EMC IAM                     
objectscale/influxdb-operator         	0.77.0       	0.77.0     	InfluxDB Operator deploys operator pod which is...
objectscale/kahm                      	2.77.0       	2.77.0     	A Helm chart for Kubernetes Applications Health...
objectscale/logging-injector          	0.77.0       	0.77.0     	Rsyslog client sidecar injector                   
objectscale/mongoose                  	0.1.3        	4.1.1      	Mongoose is a horizontally scalable and configu...
objectscale/objectscale-dcm           	0.77.0       	0.77.0     	A Helm chart for Dell EMC DCM                     
objectscale/objectscale-gateway       	0.77.0       	0.77.0     	A Helm chart for Dell EMC Objectscale Gateway     
objectscale/objectscale-graphql       	0.77.0       	0.77.0     	A Helm chart for Kubernetes                       
objectscale/objectscale-iam           	0.77.0       	0.77.0     	A Helm chart for Dell EMC IAM                     
objectscale/objectscale-manager       	0.77.0       	0.77.0     	Dell EMC ObjectScale is highly scalable, and hi...
objectscale/objectscale-portal        	0.77.0       	0.77.0     	ObjectScale Portal                                
objectscale/objectscale-vsphere       	0.77.0       	0.77.0     	ObjectScale VMware vSphere Plugin                 
objectscale/pravega-operator          	0.5.2        	0.5.2      	Pravega Operator Helm chart for Kubernetes        
objectscale/service-pod               	2.77.0       	2.77.0     	A Helm chart for Dell EMC Service Pod             
objectscale/sonobuoy                  	0.16.6       	0.16.6     	A Helm chart for sonobuoy                         
objectscale/srs-gateway               	1.2.0        	1.2.0      	A Helm chart for Dell EMC SRS Gateway Custom Re...
objectscale/statefuldaemonset-operator	0.77.0       	0.77.0     	StatefulDaemonSet operator deploys operator pod...
objectscale/supportassist             	2.77.0       	2.77.0     	Helm chart for Dell SupportAssist ESE             
objectscale/zookeeper-operator        	0.28.0       	0.28.0     	Zookeeper operator deploys a custom resource fo...
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

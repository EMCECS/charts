# Atlas Operator Chart

This chart installs the Atlas Operator using the [Helm](https://helm.sh) package manager.
You can use the operator to create and manage Atlas clusters. The operator will install
the associated resources (stateful-sets, config-maps, etc.) and handles changes made to
the cluster.

## Prerequisites

- Kubernetes 1.14+


## Customising values

Default values can be overridden when installing the operator by creating a yaml file and
passing in with the `--values` option.

_my-values.yaml:_
```
image:
  tag: v100.1
```

## Installing the Chart

Install the chart with the release name `my-release` use one of these options:
```bash
# Use the default settings
$ helm install my-release atlas-operator

# Or pass in the my-values.yaml file
$ helm install my-release --values values.yaml atlas-operator

```
> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes
the release.

If you need to reinstall the operator and CRDs from scratch, you have to manually
remove the existing CRDs. Helm does not removed CRDs automatically. This can be done
with kubectl:

```bash
$ kubectl delete crd/atlasclusters.atlas.dellemc.com
```


## Running unit tests

This chart uses the unittest plugin for helm to test expected outputs without requiring a full k8s cluster. To install:

```bash
helm plugin install https://github.com/lrills/helm-unittest
```

The unit tests can then be run:

```bash
helm unittest .
```

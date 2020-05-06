#!/usr/bin/env bash

cat <<EOT >> temp_package/vmware-config-map.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ecs-objectscale
  namespace: kube-system
  labels:
    appplatform.vmware.com/kind: supervisorservice
data:
  ecs-objectscale-crd.yaml: |-
$(awk '{printf "%4s%s\r", "", $0}' temp_package/ecs-objectscale-crd.yaml)
  ecs-objectscale-operator.yaml: |-
$(sed  's/^/    /' cat temp_package/objectscale-manager.yaml)
  ecs-objectscale.yaml: |-
    apiVersion: appplatform.wcp.vmware.com/v1alpha1
    kind: SupervisorService
    metadata:
      labels:
        controller-tools.k8s.io: "1.0"
      name: sample
      namespace: "kube-system"
    spec:
      serviceId: sample
      eula: "Please use it, it's free!"
      label: "Sample Service"
      description: "The Sample Service consumes resources and delivers nothing to society. You are welcome."
      versions: ["1.0"]
      enabled: false
EOT

awk 'NR==FNR { a[n++]=$0; next } /{PLACEHOLDER_1}/ { for (i=0;i<n;++i) printf "%4s%s\n", "", a[i]; next } 1' temp_package/ecs-objectscale-crd.yaml vmware-config-map.yaml > tmp && mv tmp vmware-config-map.yaml
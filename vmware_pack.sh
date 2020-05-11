#!/usr/bin/env bash

cat <<EOT >> temp_package/vmware-config-map.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: objectscale
  namespace: kube-system
  labels:
    appplatform.vmware.com/kind: supervisorservice
data:
  objectscale-crd.yaml: |-
$(awk '{printf "%4s%s\n", "", $0}' temp_package/objectscale-crd.yaml)
  objectscale-operator.yaml: |-
$(awk '{printf "%4s%s\n", "", $0}' temp_package/objectscale-manager.yaml)
$(awk '{printf "%4s%s\n", "", $0}' temp_package/kahm.yaml)
$(awk '{printf "%4s%s\n", "", $0}' temp_package/decks.yaml)
  objectscale.yaml: |-
    apiVersion: appplatform.wcp.vmware.com/v1alpha1
    kind: SupervisorService
    metadata:
      labels:
        controller-tools.k8s.io: "1.0"
      name: objectscale
      namespace: "kube-system"
    spec:
      serviceId: dellemc-objecstcale
      eula: "By accepting this EULA, you are agreeing to ..."
      label: "Dell EMC ObjectScale"
      description: "Dell EMC ObjectScale is a highly available and scalable object storage platform"
      versions: ["0.27.0"]
      enabled: false
EOT

# Remove trailing whitespaace
sed -i 's/[[:space:]]*$//' temp_package/vmware-config-map.yaml

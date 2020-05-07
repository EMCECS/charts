#!/usr/bin/env bash

# # Indent yaml files 4 spaces before appending to config map
# sed -i 's/^/    /' temp_package/ecs-objectscale-crd.yaml
# sed -i 's/^/    /' temp_package/objectscale-manager.yaml

# cat > temp_package/vmware-config-map.yaml <<EOL
# ---
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: ecs-objectscale
#   namespace: kube-system
#   labels:
#     appplatform.vmware.com/kind: supervisorservice
# data:
#   ecs-objectscale-crd.yaml: |-
# EOL

# cat temp_package/ecs-objectscale-crd.yaml >> temp_package/vmware-config-map.yaml

# echo "  ecs-objectscale-operator.yaml: |-" >> temp_package/vmware-config-map.yaml

# cat temp_package/objectscale-manager.yaml >> temp_package/vmware-config-map.yaml

# cat >> temp_package/vmware-config-map.yaml <<EOL
#   ecs-objectscale.yaml: |-
#     apiVersion: appplatform.wcp.vmware.com/v1alpha1
#     kind: SupervisorService
#     metadata:
#       labels:
#         controller-tools.k8s.io: "1.0"
#       name: sample
#       namespace: "kube-system"
#     spec:
#       serviceId: sample
#       eula: "Please use it, it's free!"
#       label: "Sample Service"
#       description: "The Sample Service consumes resources and delivers nothing to society. You are welcome."
#       versions: ["1.0"]
#       enabled: false
# EOL

# sed -i 's/[[:space:]]*$//' temp_package/vmware-config-map.yaml

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
$(awk '{printf "%4s%s\n", "", $0}' temp_package/ecs-objectscale-crd.yaml)
  ecs-objectscale-operator.yaml: |-
$(awk '{printf "%4s%s\n", "", $0}' temp_package/objectscale-manager.yaml)
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

sed -i 's/[[:space:]]*$//' temp_package/vmware-config-map.yaml

#'s/^/     /'  input.txt
#awk '{ sub(/[ \t]+$/, ""); temp_package/vmware-config-map.yaml }'
#awk 'NR==FNR { a[n++]=$0; next } /{PLACEHOLDER_1}/ { for (i=0;i<n;++i) printf "%4s%s\n", "", a[i]; next } 1' temp_package/ecs-objectscale-crd.yaml vmware-config-map.yaml > tmp && mv tmp vmware-config-map.yaml
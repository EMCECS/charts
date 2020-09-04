#!/usr/bin/env bash

## if its not the official namespace just bail, no plugin required.
if [ $1 != "dellemc-objectscale-system" ]
then 
    exit 0
fi


## extract the version from objectscale-manager 
objs_ver=$(grep appVersion: objectscale-manager/Chart.yaml | sed -e "s/.*: //g")

vsphere7_plugin_file="objectscale-${objs_ver}-vmware-config-map.yaml"

cat <<EOT >> temp_package/$1/yaml/${vsphere7_plugin_file}
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
$(awk '{printf "%4s%s\n", "", $0}' temp_package/$1/yaml/objectscale-crd.yaml)
  objectscale-operator.yaml: |-
$(awk '{printf "%4s%s\n", "", $0}' temp_package/$1/yaml/objectscale-manager.yaml)
$(awk '{printf "%4s%s\n", "", $0}' temp_package/$1/yaml/kahm.yaml)
$(awk '{printf "%4s%s\n", "", $0}' temp_package/$1/yaml/decks.yaml)
  objectscale.yaml: |-
    apiVersion: appplatform.wcp.vmware.com/v1alpha1
    kind: SupervisorService
    metadata:
      labels:
        controller-tools.k8s.io: "1.0"
      name: objectscale
      namespace: "kube-system"
    spec:
      serviceId: dellemc-objectscale
      label: "Dell EMC ObjectScale"
      description: |
        Dell EMC ObjectScale is a dynamically scalable, secure, and multi-tenant object storage platform
        for on-premises and cloud use cases.  It supports advanced storage functionality including
        comprehensive S3 support, flexible erasure-coding, data-at-rest encryption, compression,
        and scales capacity and performance linearly.
      versions: ["${objs_ver}"]
      enableHostLocalStorage: true
      enabled: false
      eula: |+
        $(sed "s/^/        /" ./dellemc_eula.txt)
EOT

# Remove trailing whitespaace
sed -i 's/[[:space:]]*$//' temp_package/$1/yaml/${vsphere7_plugin_file}

cp -p ./vmware/deploy-objectscale-plugin.sh temp_package/$1/scripts 
cat temp_package/$1/yaml/${vsphere7_plugin_file} >> temp_package/$1/scripts/deploy-objectscale-plugin.sh 
echo "EOF" >> temp_package/$1/scripts/deploy-objectscale-plugin.sh

echo 'echo' >> temp_package/$1/scripts/deploy-objectscale-plugin.sh
echo 'echomsg "In vSphere7 UI Navigate to Workload-Cluster > Supervisor Services > Services"' >> temp_package/$1/scripts/deploy-objectscale-plugin.sh
echo 'echomsg "Select Dell EMC ObjectScale then Enable"'  >> temp_package/$1/scripts/deploy-objectscale-plugin.sh

chmod 700 temp_package/$1/scripts/deploy-objectscale-plugin.sh

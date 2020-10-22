#!/usr/bin/env bash

## official namespace
namespace="dellemc-objectscale-system"

## supervisor service name
label="Dell EMC ObjectScale"

## extract the version from objectscale-manager 
objs_ver=$(grep appVersion: objectscale-manager/Chart.yaml | sed -e "s/.*: //g")

vsphere7_plugin_file="objectscale-${objs_ver}-vmware-config-map.yaml"

service_id=$1
if [ ${service_id} != "objectscale" ]
then
     label="${label}-${service_id}"
     sed -i "s/SERVICE_ID/-${service_id}/g" temp_package/yaml/objectscale-manager.yaml
else sed -i "s/SERVICE_ID//g" temp_package/yaml/objectscale-manager.yaml
fi

cp -p ./vmware/october-build-hack.yaml temp_package/yaml

cat <<EOT >> temp_package/yaml/${vsphere7_plugin_file}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${service_id}
  namespace: vmware-system-appplatform-operator-system
  labels:
    appplatform.vmware.com/kind: supervisorservice
data:
  ${service_id}-crd.yaml: |-
$(awk '{printf "%4s%s\n", "", $0}' temp_package/yaml/objectscale-crd.yaml)
  ${service_id}-operator.yaml: |-
$(awk '{printf "%4s%s\n", "", $0}' temp_package/yaml/objectscale-manager.yaml)
$(awk '{printf "%4s%s\n", "", $0}' temp_package/yaml/kahm.yaml)
$(awk '{printf "%4s%s\n", "", $0}' temp_package/yaml/decks.yaml)
$(awk '{printf "%4s%s\n", "", $0}' temp_package/yaml/october-build-hack.yaml)
  ${service_id}.yaml: |-
    apiVersion: appplatform.wcp.vmware.com/v1alpha1
    kind: SupervisorService
    metadata:
      labels:
        controller-tools.k8s.io: "1.0"
      name: ${service_id}
      namespace: "kube-system"
    spec:
      serviceId: dellemc-${service_id}
      label: ${label}
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

## Remove trailing whitespaace
sed -i 's/[[:space:]]*$//' temp_package/yaml/${vsphere7_plugin_file}

## Template the namespace value
sed -i "s/$namespace/{{ .service.namespace }}/g" temp_package/yaml/${vsphere7_plugin_file}

cp -p ./vmware/deploy-objectscale-plugin.sh temp_package/scripts 

## Template the service_id value
sed -i "s/SERVICE_ID/${service_id}/" temp_package/scripts/deploy-objectscale-plugin.sh

cat temp_package/yaml/${vsphere7_plugin_file} >> temp_package/scripts/deploy-objectscale-plugin.sh 
echo "EOF" >> temp_package/scripts/deploy-objectscale-plugin.sh

echo 'echo' >> temp_package/scripts/deploy-objectscale-plugin.sh
echo 'echomsg "In vSphere7 UI Navigate to Workload-Cluster > Supervisor Services > Services"' >> temp_package/scripts/deploy-objectscale-plugin.sh
echo 'echomsg "Select Dell EMC ObjectScale then Enable"'  >> temp_package/scripts/deploy-objectscale-plugin.sh

chmod 700 temp_package/scripts/deploy-objectscale-plugin.sh

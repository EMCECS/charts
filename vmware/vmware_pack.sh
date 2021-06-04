#!/usr/bin/env bash

## official namespace
namespace="dellemc-objectscale-system"

## supervisor service name
label="Dell EMC ObjectScale"

sed_inplace=("-i")
uname_s=$(uname -s)
if [ "$uname_s" == "Darwin" ]; then
	sed_inplace+=(".orig")
fi


## extract the version from objectscale-manager 
objs_ver=$(grep appVersion: objectscale-manager/Chart.yaml | sed -e "s/.*: //g")

vsphere7_plugin_file="objectscale-${objs_ver}-vmware-config-map.yaml"

extra_crd_install=""
actual_crd=""

service_id=$1

## need to restrict service_id due to services creating long hostnames that exceed 127 chars.
if [ ${#service_id} -ge 12 ]
then
    echo -e "\n\nERROR: Service ID: \"$service_id\" is ${#service_id} chars, must be less than 12\n"
    exit 1
fi


svc_vs7u3_id=$service_id

if [ ${service_id} != "objectscale" ]
then
     svc_vs7u3_id="objectscale-${service_id}"  # in VS7U3+ need to append custom name to svcid
     label="${label}-${service_id}"
     sed "${sed_inplace[@]}" "s/SERVICE_ID/-${service_id}/g" temp_package/yaml/objectscale-manager.yaml

     extra_crd_install=$(cat <<EOF
# manually install CRD because of OBSDEF-8341, also tag text for automation
echomsg "Manually installing CRD because of non-default service ID ${service_id}"
cat <<'EOT' | kubectl apply -f - 
$(cat temp_package/yaml/objectscale-crd.yaml)
EOT

if [ \$? -ne 0 ]
then
    echomsg "ERROR unable to apply CRD yaml"
    exit 1
fi 
EOF
)

else 
     sed "${sed_inplace[@]}" "s/SERVICE_ID//g" temp_package/yaml/objectscale-manager.yaml
     actual_crd=$(awk '{printf "%4s%s\n", "", $0}' temp_package/yaml/objectscale-crd.yaml)
fi

objs_desc="$label is a dynamically scalable, secure, and multi-tenant object storage platform
        for on-premises and cloud use cases."

objs_long_desc='It supports advanced storage functionality including
        comprehensive S3 support, flexible erasure-coding, data-at-rest encryption, compression,
        and scales capacity and performance linearly.'

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
${actual_crd}
  ${service_id}-operator.yaml: |-
$(awk '{printf "%4s%s\n", "", $0}' temp_package/yaml/objectscale-manager.yaml)
$(awk '{printf "%4s%s\n", "", $0}' temp_package/yaml/kahm.yaml)
$(awk '{printf "%4s%s\n", "", $0}' temp_package/yaml/decks.yaml)
$(awk '{printf "%4s%s\n", "", $0}' temp_package/yaml/logging-injector.yaml)
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
        $objs_desc  $objs_long_desc
      versions: ["${objs_ver}"]
      enableHostLocalStorage: true
      enabled: false
      eula: |+
        $(sed "s/^/        /" ./dellemc_eula.txt)
EOT

## Remove trailing whitespaace
sed "${sed_inplace[@]}" 's/[[:space:]]*$//' temp_package/yaml/${vsphere7_plugin_file}

## Template the namespace value
sed "${sed_inplace[@]}" "s/$namespace/{{ .service.namespace }}/g" temp_package/yaml/${vsphere7_plugin_file}
sed "${sed_inplace[@]}" "s/$namespace/{{ .service.namespace }}/g" temp_package/yaml/*

## Template registry from supervisor service input
sed "${sed_inplace[@]}" -e "s/REGISTRYTEMPLATE/{{ .Values.registryName }}/g" temp_package/yaml/*

## Template docker username and password from supervisor service input
dockersecret='{{printf "{\\"auths\\": {\\"%s\\": {\\"auth\\": \\"%s\\"}}}" .Values.registryName (printf "%s:%s" .Values.registryUsername .Values.registryPasswd | b64enc) | b64enc}}'
sed "${sed_inplace[@]}" -e "s/DOCKERSECRETPLACEHOLDER/$dockersecret/g" temp_package/yaml/*

## Template the vsphere service prefix value
sed "${sed_inplace[@]}" "s/VSPHERE_SERVICE_PREFIX_VALUE/{{ .service.prefix }}/g" temp_package/yaml/${vsphere7_plugin_file}
sed "${sed_inplace[@]}" "s/VSPHERE_SERVICE_PREFIX_VALUE/{{ .service.prefix }}/g" temp_package/yaml/*

cp -p ./vmware/deploy-objectscale-plugin.sh temp_package/scripts 

### Building vSphere 7.0 U3+ ObjectScale WCP Plugin
set -x
vsphere_script=create-vsphere-app.py
wget -O vmware/$vsphere_script https://asdrepo.isus.emc.com/artifactory/objectscale-tps-staging-local-mw/com/vmware/create-vsphere-app/7.0u3/$vsphere_script
if [ $? != 0 ]
then
    echo "Unable to pull down create-vsphere-app.py script to build ObjectScale WCP plugin"
    exit 1
fi

chmod +x vmware/$vsphere_script
mkdir -p temp_package/yaml/u3

(cd temp_package/yaml; cat logging-injector.yaml objectscale-manager.yaml kahm.yaml decks.yaml > u3/objectscale-vsphere-service-src.yaml )
vmware/$vsphere_script -c temp_package/yaml/objectscale-crd.yaml -p temp_package/yaml/u3/objectscale-vsphere-service-src.yaml -v $objs_ver --display-name "$label" \
  --description "$objs_desc" -e dellemc_eula.txt -o temp_package/yaml/u3/objectscale-${objs_ver}-vsphere-service.yaml $svc_vs7u3_id

if [ $? -ne 0 ]
then
    echo "error: unable to generate ObjectScale WCP plugin"
    exit 1
fi
set +x

## Template the service_id value
sed "${sed_inplace[@]}" "s/SERVICE_ID/${service_id}/" temp_package/scripts/deploy-objectscale-plugin.sh

cat temp_package/yaml/${vsphere7_plugin_file} >> temp_package/scripts/deploy-objectscale-plugin.sh 
echo "EOF" >> temp_package/scripts/deploy-objectscale-plugin.sh

cat <<EOF >> temp_package/scripts/deploy-objectscale-plugin.sh

if [ \$? -ne 0 ]
then
    echomsg "ERROR unable to apply $label plugin"
    exit 1
fi

${extra_crd_install}

echo
echomsg "In vSphere7 UI Navigate to Workload-Cluster > Supervisor Services > Services"
echomsg "Select $label then Enable"
EOF

chmod 500 temp_package/scripts/deploy-objectscale-plugin.sh


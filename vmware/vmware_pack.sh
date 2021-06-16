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

svc_vs7u3_id=$service_id
svc_vs7u3_crd_opts=" -c temp_package/yaml/objectscale-crd.yaml "

if [ ${service_id} != "objectscale" ]
then

    ## Restricting custom service id to max 8 chars for U3 master-proxy pods 
    ## and alleviate any long hostnames for components such as kahm postgres

    # need to restrict service_id due to services creating long hostnames that exceed 127 chars.
    if [ ${#service_id} -gt 8 ]
    then
        echo -e "\n\nERROR: Custom Service ID: \"$service_id\" is ${#service_id} chars, max 8 characters\n"
        exit 1
    fi
    svc_vs7u3_id="objectscale-${service_id}"  # in VS7U3+ need to append custom name to svcid
    label="${label}-${USER}-${service_id}"
    sed "${sed_inplace[@]}" "s/SERVICE_ID/-${service_id}/g" temp_package/yaml/objectscale-manager.yaml
    
    ## apply crds outside of the plugin
    svc_vs7u3_crd_opts=" "
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

### Building the U2 (the edge) plugin script

vs7u2_plugin_script="temp_package/scripts/deploy-objectscale-plugin.sh"

## Template the service_id value
sed "${sed_inplace[@]}" "s/SERVICE_ID/${service_id}/" $vs7u2_plugin_script

cat vmware/common_funcs.sh vmware/deploy-main.sh temp_package/yaml/${vsphere7_plugin_file} >> $vs7u2_plugin_script

echo "EOF" >> $vs7u2_plugin_script

cat <<EOF >> $vs7u2_plugin_script

if [ \$? -ne 0 ]
then
    echomsg "ERROR unable to apply $label plugin"
    exit 1
fi

${extra_crd_install}

echo
echomsg "In vSphere7 UI Navigate to Workload-Cluster > Supervisor Services > Services"
echomsg "Select Dell EMC ObjectScale then Enable"
EOF

chmod 500 $vs7u2_plugin_script

### end credits U2

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
mkdir -p temp_package/u3/tmp

(cd temp_package/yaml; cat logging-injector.yaml objectscale-manager.yaml kahm.yaml decks.yaml > ../u3/tmp/objectscale-vsphere-service-src.yaml )
sed "${sed_inplace[@]}" "s/dellemc-${service_id}/$svc_vs7u3_id/g" temp_package/u3/tmp/objectscale-vsphere-service-src.yaml

## Append the 7.0 U3 Persistence Service Config to our yaml.  Eventually the 'create-vsphere-app.py' above will support this
cat <<EOP >> temp_package/u3/tmp/objectscale-vsphere-service-src.yaml
---
#PersistenceServiceConfiguration
apiVersion: psp.wcp.vmware.com/v1beta1
kind: PersistenceServiceConfiguration
metadata:
  name: {{ .service.prefix }}-psp-config
  namespace: {{ .service.namespace }}
spec:
  enableHostLocalStorage: true
  serviceID: $svc_vs7u3_id
---
EOP

vmware/$vsphere_script $svc_vs7u3_crd_opts -p temp_package/u3/tmp/objectscale-vsphere-service-src.yaml -v $objs_ver --display-name "$label" \
  --description "$objs_desc" -e dellemc_eula.txt -o temp_package/u3/objectscale-${objs_ver}-vsphere-service.yaml $svc_vs7u3_id

if [ $? -ne 0 ]
then
    echo "error: unable to generate ObjectScale WCP plugin"
    exit 1
fi

## Now generating U3 preinstall script until OBSDEF-7223 is fixed.

vs7u3_pre_install_script="temp_package/u3/objectscale-pre-install.sh"
cp vmware/deploy-objectscale-plugin.sh $vs7u3_pre_install_script
cat vmware/common_funcs.sh >> $vs7u3_pre_install_script

cat <<EOS >> $vs7u3_pre_install_script
add_vsphere7_clusterrole_rules

${extra_crd_install}

EOS

chmod 500 $vs7u3_pre_install_script


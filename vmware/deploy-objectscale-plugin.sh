#!/bin/bash 
##
## Copyright (c) 2020. Dell Inc. or its subsidiaries. All Rights Reserved.
##
## This software contains the intellectual property of Dell Inc.
## or is licensed to Dell Inc. from third parties. Use of this software
## and the intellectual property contained therein is expressly limited to the
## terms and conditions of the License Agreement under which it is provided by or
## on behalf of Dell Inc. or its subsidiaries.

service_id="SERVICE_ID"

echomsg () {

    if [ ! -d ./log ]
    then 
	    mkdir ./log
    fi 

    curdate=$(date +"%y.%m.%d %H:%M:%S")

    case $1 in
	    log)
	        msg=$2
            echo "$curdate : $msg"  >> $logfile
	        return
	        ;;
	    stl|starline)
	        msg="**********************************************"
	        ;;
	    dl|doubleline)
	        msg="=============================================="
	        ;;
        sl|singleline)
	        msg="----------------------------------------------"
	        ;;
        nl|newline)
	        msg=" "
	        ;;
	    *)
	        msg="$1"
	        ;;
    esac

    ## ok now show the message
    echo "$curdate : $msg" | tee -a $logfile

} #end echomsg

## add_vsphere7_clusterole_rules 
## Add rules needed to apply our plugin
add_vsphere7_clusterrole_rules () {
  vsphere7AppRoles="kubectl get -n vmware-system-appplatform-operator-system clusterrole vmware-system-appplatform-operator-manager-role  -o yaml"
  numRoles=$(eval ${vsphere7AppRoles} | egrep -c -e "- batch|- app.k8s.io")

  if [ ${numRoles} -le 1 ] 
  then
      echomsg "Adding roles to app platform"
      cat <<'EOT' > /tmp/newrules.yaml
- apiGroups:
  - batch
  resources:
  - cronjobs
  - jobs
  verbs:
  - get
  - list
  - create
  - update
  - patch
  - delete
- apiGroups:
  - app.k8s.io
  resources:
  - applications
  verbs:
  - '*'
EOT
      eval ${vsphere7AppRoles} > /tmp/currrules.yaml
      kubectl apply -f <(cat <(cat /tmp/currrules.yaml) /tmp/newrules.yaml)
      if [ $? -ne 0 ] 
      then
          echomsg "Error: unable to apply the clusterrole rules for clusterrole vmware-system-appplatform-operator-manager-role"
          exit 1
      fi
  fi 
}
## main()
curdate=`date +"%y%m%d"`
logfile="./log/deploy-objectscale-$curdate.log"

echomsg "Starting deployment of ObjectScale"
echomsg dl

echomsg "Locating kubectl..."
kubectl version --short=true > /tmp/kubectl_version.txt
if [ $? -ne 0 ]
then
    echomsg "error unable to located kubectl in the PATH"
    exit 1
fi 
kctlVers=$(cat /tmp/kubectl_version.txt)
echomsg "$kctlVers"

kubectl -n vmware-system-appplatform-operator-system get cm ${service_id} 2>/dev/null
if [ $? -eq 0 ]
then
    echomsg "ObjectScale Plugin \"${service_id}\" has already been deployed"
    echomsg "It must be disabled and removed before a new one can be applied"
    exit 1
fi

service_port=`kubectl -n kube-system get svc kube-apiserver-authproxy-svc -o jsonpath='{.spec.ports[0].targetPort}'`
if [ ${service_port} -ne 443 ]
then
    echomsg "The kube-apiserver-authproxy-svc is configured with incorrect port \"${service_port}\" and will be updated now"
    kubectl -n kube-system patch svc kube-apiserver-authproxy-svc --type=json -p '[{"op":"replace", "path":"/spec/ports/0/targetPort", "value":443}]'
    if [ $? -eq 0 ]
    then
        echomsg "Successfully updated the kube-apiserver-authproxy-svc targetPort to 443"
    else
        echomsg "Unable to update the targetPort of kube-apiserver-authproxy-svc to 443"
        exit 1
    fi
fi

## Now check if the api groups have been added for VMware vSphere7 app platform:
add_vsphere7_clusterrole_rules

echomsg dl 
echomsg "Adding the ObjectScale plugin for vSphere7"

## rest of the code below is built with vmware/vmware_pack.sh
cat <<'EOF' | kubectl apply -f - 2>/dev/null

#!/bin/bash

. ./deploy-objectscale-plugin.sh 

  vsphere7AppRoles="kubectl get -n vmware-system-appplatform-operator-system clusterrole vmware-system-appplatform-operator-manager-role  -o yaml"
  numRoles=$(eval ${vsphere7AppRoles} | egrep -c -e "- batch|- app.k8s.io")

  if [ ${numRoles} -le 1 ] 
  then
      echomsg log "Adding roles to app platform"
      cat <<'EOT' > /tmp/newroles.yaml
- apiGroups:
  - batch
  resources:
  - cronjobs
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
      eval ${vsphere7AppRoles} > /tmp/currroles.yaml
      kubectl apply -f <(cat <(cat /tmp/currroles.yaml) /tmp/newroles.yaml)

  fi

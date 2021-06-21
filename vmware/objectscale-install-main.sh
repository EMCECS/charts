#!/usr/bin/env bash

# usage function
function usage()
{
   cat << HEREDOC

   Usage: $progname  --set type=<install_type> --set helmrepo=<repo> --set primaryStorageClassName=... [--namespace <namespace] 
                        [--verbose] [--dry-run]

   required arguments:
     --set type={install|upgrade|remove}    set install type
     --set helmrepo=repo_name               location of helm repository or directory where charts located
     --set primaryStorageClassName=<string> name of storage class to install high performance persistent volumes (e.g. csi-baremetal-ssdlvg)

   optional arguments:
     --set global.registry=<string>           where to pull ObjectScale container images
     --set secondaryStorageClassName=<string> name of storage class for normal performance persistent volumes (e.g. csi-baremetal-hddlvg)
     -n, --namespace string                   k8s namespace to install ObjectScale management components
     -h, --help           show this help message and exit
     -v, --verbose        increase the verbosity of the bash script
     --dry-run            do a dry run, dont change any files

HEREDOC
}  

function parse_set_opts()
{
    nameval="$1"
    namevalArr=(${nameval//=/ })
    setName=${namevalArr[0]}
    setValue=${namevalArr[1]}
    case $setName in 
        "type")                    
            install_type=$setValue 
            ;;
        "helmrepo")                 
            helm_repo=$setValue 
            ;;
        "primaryStorageClassName")  
            primaryStorageClassName=$setValue 
            ;;
        "secondaryStorageClassName") 
            secondaryStorageClassName=$setValue
            ;;
        "global.registry")          
            registry="$nameval"
            registryName="$setValue"
            ;;
        *)  
            set_opts+=($nameval) ;;
    esac

}

function install_portal() 
{
    uiStorageClass=${secondaryStorageClassName:-$primaryStorageClassName}
    set -x 
    helm install objectscale-ui ${helm_repo}/objectscale-portal $dryrun --set global.platform=$platform,$registry --set global.storageClassName=$uiStorageClass
    hexit=$?
    if [ $? -ne 0 ]
    then
        echo "ERROR: unable to install UI"
    fi

}

function apply_app_crd()
{
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/application/master/config/crd/bases/app.k8s.io_applications.yaml
}

function install_objectscale_manager() 
{
    mkdir -p ./tmp
    helm show values ${helm_repo}/objectscale-manager > ./tmp/values.yaml   
    helm template --show-only templates/objectscale-manager-custom-values.yaml objectscale-manager $helm_repo/objectscale-manager \
        --set useCustomValues=true \
        --set global.platform=OpenShift \
        --set $registry \
        --set hooks.registry=$registryName,global.storageClassName=$primaryStorageClassName \
        --set ecs-monitoring.influxdb.persistence.storageClassName=$primaryStorageClassName \
        --set global.monitoring_registry=$registryName \
		--set objectscale-monitoring.influxdb.persistence.storageClassName=$primaryStorageClassName \
	    --set objectscale-monitoring.rsyslog.persistence.storageClassName=$secondaryStorageClassName \
         -f ./tmp/values.yaml > ./tmp/objectscale-manager-custom-values.yaml && sed -i '1d' ./tmp/objectscale-manager-custom-values.yaml
    grep -v "{{" objectscale-manager/templates/objectscale-manager-custom-values.yaml | yq eval -j -I 0 > objectscale-manager/customvalues.json
    ## now gen the app resource
    helm template --show-only templates/objectscale-manager-app.yaml objectscale-manager ${helm_repo}/objectscale-manager  \
	    -f ./tmp/values.yaml -f ./tmp/objectscale-manager-custom-values.yaml > ./tmp/objectscale-manager-app.yaml
	sed -i 's/createApplicationResource\\":true/createApplicationResource\\":false/g' ./tmp/objectscale-manager-app.yaml && \
	sed -i 's/app.kubernetes.io\/managed-by: Helm/app.kubernetes.io\/managed-by: nautilus/g' ./tmp/objectscale-manager-app.yaml

}


# initialize variables
progname=$(basename $0)
verbose=0
platform="OpenShift"

# use getopt and store the output into $OPTS
# note the use of -o for the short options, --long for the long name options
# and a : for any option that takes a parameter
OPTS=$(getopt -o "hvn:" --long "help,namespace:,set:,verbose,dry-run" -n "$progname" -- "$@")
if [ $? != 0 ] ; then echo "Error in command line arguments." >&2 ; usage; exit 1 ; fi
eval set -- "$OPTS"

set_opts=()
while true; do
  # uncomment the next line to see how shift is working
  # echo "\$1:\"$1\" \$2:\"$2\""
  case "$1" in
    -h | --help ) usage; exit; ;;
    --set ) parse_set_opts $2 ; shift 2 ;;
    --dry-run ) dryrun="--dry-run"; shift ;;
    -v | --verbose ) verbose=$((verbose + 1)); shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if (( $verbose > 0 )); then

   # print out all the parameters we read in
   cat <<EOM
   set_opts=${set_opts[*]}
   verbose=$verbose
   dryrun=$dryrun
   type=$install_type
   helmrepo=$helm_repo
   sc=$primaryStorageClassName
EOM
fi

## check for helm and kubectl in the path
helm --help > /dev/null
if [ $? -ne 0 ] 
then 
    echo "helm not found, please install from https://helm.sh and add to your PATH"
    exit 1
fi 

kubectl version 
if [ $? -ne 0 ]
then
    echo "ERROR: unable to get versions of k8s connection, please fix"
    exit 1
fi

case $install_type in 
    install)
        install_portal
        apply_app_crd
        install_objectscale_manager
        ;;
    upgrade)
        ;;
    remove|uninstall)
        helm delete objectscale-ui 
        ;;
    *)
        echo "ERROR: invalid install type specified: must be 'install|remove|upgrade"
        exit 1
        ;;
esac 


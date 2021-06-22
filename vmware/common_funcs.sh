
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
  numRoles=$(eval ${vsphere7AppRoles} | egrep -c -e "- app.k8s.io")

  ## if we didn't fine app resources then add them
  if [ ${numRoles} -le 0 ]
  then
      echomsg "Adding roles to app platform"
      cat <<'EOT' > /tmp/newrules.yaml
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

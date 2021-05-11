set -xe

usage() {
    cat <<EOF
usage: ${0} [OPTIONS]

The following flags are required.
       --type, -t             service procedure type(precheck, recover, postcheck).
       --timeout, -o          timeout for recovery process in seconds.
EOF
    exit 1
}

precheck() {
if curl "http://`hostname -i`:8080/api/v1/autorecovery/list_under_replicated_ledger" | grep -q "No under replicated ledgers found"
then
  echo "pass precheck!"
	exit 0
else
	echo "under_replicated_ledger not empty, precheck failed!"
	exit 1
fi
}

postcheck() {
if curl "http://`hostname -i`:8080/api/v1/autorecovery/list_under_replicated_ledger" | grep -q "No under replicated ledgers found"
then
  echo "pass postcheck!"
	exit 0
else
	echo "under_replicated_ledger not empty, postcheck failed!"
	exit 1
fi
}


recovery() {
if curl "http://`hostname -i`:8080/api/v1/autorecovery/list_under_replicated_ledger" | grep -q "No under replicated ledgers found"
then
	if timeout ${timeout_seconds}s /opt/bookkeeper/bin/bookkeeper shell recover `hostname -i`:3181 -f |tee /opt/bookkeeper/logs/recover_`date +%s`.log| grep  -q "OK: No problem"
	then
	  echo "recovery succeeded!"
	  exit 0
	else
		echo "recovery failed!"
		exit 1
	fi
else
	echo "under_replicated_ledger not empty, recovery failed!"
	exit 1
fi
}

while [[ $# -gt 0 ]]; do
    case ${1} in
        -t|--type)
            type="$2"
            shift
            shift
            ;;
        -o|--timeout)
            timeout_seconds="$2"
            shift
            shift
            ;;
        *)
            usage
            shift
            ;;
    esac
done

case ${type} in
    precheck)
        precheck
        ;;
    postcheck)
        postcheck
        ;;
    recover)
        recovery
        ;;
    *)
        usage
        ;;
esac
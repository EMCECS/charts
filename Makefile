HELM_VERSION := v2.12.3
HELM_URL     := https://storage.googleapis.com/kubernetes-helm
HELM_TGZ      = helm-${HELM_VERSION}-linux-amd64.tar.gz
YQ_VERSION   := 2.2.1
YAMLLINT_VERSION := 1.14.0
CHARTS := ecs-cluster ecs-flex-operator mongoose zookeeper-operator decks kahm srs-gateway dks-testapp fio-test sonobuoy dellemc-license service-pod
DECKSCHARTS := decks kahm srs-gateway dks-testapp dellemc-license service-pod
FLEXCHARTS := ecs-cluster ecs-flex-operator zookeeper-operator

test:
	for CHART in ${CHARTS}; do \
		set -x ; \
		helm lint $$CHART ; \
		helm unittest $$CHART ; \
		if [ "$${?}" -eq "1" ] ; then \
			exit 1 ; \
		fi ; \
		yamllint -c .yamllint.yml -s $$CHART/Chart.yaml $$CHART/values.yaml ; \
		if [ "$${?}" -eq "1" ] ; then \
			exit 1 ; \
		fi ; \
	done
	yamllint -c .yamllint.yml -s .yamllint.yml .travis.yml

dep:
	wget -q ${HELM_URL}/${HELM_TGZ}
	tar xzf ${HELM_TGZ} -C /tmp --strip-components=1
	PATH=`pwd`/linux-amd64/:$PATH
	chmod +x /tmp/helm
	helm init --client-only
	helm plugin list | grep -q "unittest" ; \
	if [ "$${?}" -eq "1" ] ; then \
		helm plugin install https://github.com/lrills/helm-unittest ; \
 	fi
	export PATH=$PATH:/tmp
	sudo pip install yamllint=="${YAMLLINT_VERSION}"
	sudo pip install yq=="${YQ_VERSION}"

decksver:
	if [ -z $${DECKSVER} ] ; then \
		echo "Missing DECKSVER= param" ; \
		exit 1 ; \
	fi
	
	if [ -z $${DCHARTVER} ] ; then \
		echo "Missing DCHARTVER= param" ; \
		exit 1 ; \
	fi
	
	echo "looking for yq command"
	which yq
	echo "Found it"
	for CHART in ${DECKSCHARTS}; do  \
		echo "Setting version $$DECKSVER in $$CHART" ;\
		yq w -i $$CHART/Chart.yaml appVersion $${DECKSVER} ; \
		yq w -i $$CHART/Chart.yaml version $${DCHARTVER} ; \
		echo "---\n`cat $$CHART/Chart.yaml`" > $$CHART/Chart.yaml ; \
		sed -i -e "s/^\([ ]*\)tag:.*/\1tag: $${DECKSVER}/" $$CHART/values.yaml; \
	done ;

flexver:
	if [ -z $${FLEXVER} ] ; then \
		echo "Missing FLEXVER= param" ; \
		exit 1 ; \
	fi
	echo "looking for yq command"
	which yq
	echo "Found it"
	for CHART in ${FLEXCHARTS}; do  \
		echo "Setting version $$FLEXVER in $$CHART" ;\
		yq w -i $$CHART/Chart.yaml appVersion $${FLEXVER} ; \
		yq w -i $$CHART/Chart.yaml version $${FLEXVER} ; \
		echo "---\n`cat $$CHART/Chart.yaml`" > $$CHART/Chart.yaml ; \
		sed -i -e "s/^\([ ]*\)tag:.*/\1tag: $${FLEXVER}/" $$CHART/values.yaml; \
	done ;

build:
	echo "looking for yq command"
	which yq
	echo "Found it"
	REINDEX=0; \
	for CHART in ${CHARTS}; do \
		set -x; \
		CURRENT_VER=`yq r $$CHART/Chart.yaml version` ; \
		yq r docs/index.yaml "entries.$${CHART}[*].version" | grep -q "\- $${CURRENT_VER}$$" ; \
		if [ "$${?}" -eq "1" ] || [ "$${REBUILDHELMPKG}" ] ; then \
		    echo "Updating package for $${CHART}" ; \
		    helm dep update $${CHART}; \
			helm package $${CHART} --destination docs ; \
			REINDEX=1 ; \
		else  \
		    echo "Packages for $${CHART} are up to date" ; \
		fi ; \
	done ; \
	if [ "$${REINDEX}" -eq "1" ]; then \
		cd docs && helm repo index . ; \
	fi

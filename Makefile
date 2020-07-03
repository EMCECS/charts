HELM_VERSION := v3.0.3
HELM_URL     := https://get.helm.sh
HELM_TGZ      = helm-${HELM_VERSION}-linux-amd64.tar.gz
YQ_VERSION   := 2.4.1
YAMLLINT_VERSION := 1.20.0
CHARTS := ecs-cluster objectscale-manager mongoose zookeeper-operator atlas-operator decks kahm srs-gateway dks-testapp fio-test sonobuoy dellemc-license service-pod
DECKSCHARTS := decks kahm srs-gateway dks-testapp dellemc-license service-pod
FLEXCHARTS := ecs-cluster objectscale-manager

# packaging
MANAGER_MANIFEST := objectscale-manager.yaml
KAHM_MANIFEST    := kahm.yaml
DECKS_MANIFEST   := decks.yaml
PACKAGE_NAME     := objectscale-charts-package.tgz
NAMESPACE         = dellemc-objectscale-system
TEMP_PACKAGE     := temp_package/${NAMESPACE}
REGISTRY          = objectscale
DECKS_REGISTRY	  = ${REGISTRY}
KAHM_REGISTRY     = ${REGISTRY}
STORAGECLASSNAME  = dellemc-objectscale-highly-available

clean: clean-package

test:
	helm lint ${CHARTS} --set product=objectscale
	yamllint -c .yamllint.yml */Chart.yaml */values.yaml
	yamllint -c .yamllint.yml -s .yamllint.yml .travis.yml
	helm unittest ${CHARTS}

dep:
	wget -q ${HELM_URL}/${HELM_TGZ}
	tar xzf ${HELM_TGZ} -C /tmp --strip-components=1
	PATH=`pwd`/linux-amd64/:$PATH
	chmod +x /tmp/helm
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
		sed -i -e "0,/^tag.*/s//tag: $${DECKSVER}/"  $$CHART/values.yaml; \
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
		sed -i -e "0,/^tag.*/s//tag: $${FLEXVER}/"  $$CHART/values.yaml; \
	done ;

build:
	@echo "looking for yq command"
	which yq
	@echo "Ensure no helm repo accessible" 
	helm repo list | grep .; \
        if [ $${?} -eq 0 ]; then exit 1; fi
	REINDEX=0; \
	for CHART in ${CHARTS}; do \
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

package: clean-package create-temp-package create-manifests combine-crds create-vmware-package archive-package
create-temp-package:
	mkdir -p ${TEMP_PACKAGE}/yaml 
	mkdir -p ${TEMP_PACKAGE}/scripts


combine-crds:
	cp -R objectscale-manager/crds ${TEMP_PACKAGE}
	cp -R atlas-operator/crds ${TEMP_PACKAGE}
	cp -R zookeeper-operator/crds ${TEMP_PACKAGE}
	cp -R kahm/crds ${TEMP_PACKAGE}
	cp -R decks/crds ${TEMP_PACKAGE}
	cat ${TEMP_PACKAGE}/crds/*.yaml > ${TEMP_PACKAGE}/yaml/objectscale-crd.yaml
	## Remove # from crd to prevent app-platform from crashing in 7.0P1
	sed -i -e "/^#.*/d" ${TEMP_PACKAGE}/yaml/objectscale-crd.yaml
	rm -rf ${TEMP_PACKAGE}/crds

create-vmware-package:
	./vmware/vmware_pack.sh ${NAMESPACE}

create-manifests: create-manager-manifest create-kahm-manifest create-decks-manifest create-deploy-script

create-manager-manifest: create-temp-package
	helm template objectscale-manager ./objectscale-manager -n ${NAMESPACE} \
	--set global.platform=VMware --set global.watchAllNamespaces=false \
	--set sonobuoy.enabled=false --set global.registry=${REGISTRY} \
	--set global.storageClassName=${STORAGECLASSNAME} \
	--set logReceiver.create=true --set logReceiver.type=Syslog \
	--set logReceiver.persistence.storageClassName=${STORAGECLASSNAME} \
	-f objectscale-manager/values.yaml >> ${TEMP_PACKAGE}/yaml/${MANAGER_MANIFEST}

create-kahm-manifest: create-temp-package
	helm template kahm ./kahm -n ${NAMESPACE} --set global.platform=VMware \
	--set global.watchAllNamespaces=false --set global.registry=${REGISTRY} \
	--set storageClassName=${STORAGECLASSNAME} -f kahm/values.yaml >> ${TEMP_PACKAGE}/yaml/${KAHM_MANIFEST}

create-decks-manifest: create-temp-package
	helm template decks ./decks -n ${NAMESPACE} --set global.platform=VMware \
	--set global.watchAllNamespaces=false --set global.registry=${REGISTRY} \
	--set storageClassName=${STORAGECLASSNAME} -f decks/values.yaml >> ${TEMP_PACKAGE}/yaml/${DECKS_MANIFEST}

create-deploy-script: create-temp-package
	echo "kubectl apply -f ../yaml/objectscale-manager.yaml -f ../yaml/decks.yaml -f ../yaml/kahm.yaml" > ${TEMP_PACKAGE}/scripts/deploy-ns-${NAMESPACE}.sh
	sed -n "/fio-pvc/,/^---/p" ${TEMP_PACKAGE}/yaml/objectscale-manager.yaml > ${TEMP_PACKAGE}/yaml/fio-pvc.yaml
	echo "sleep 1" >> ${TEMP_PACKAGE}/scripts/deploy-ns-${NAMESPACE}.sh
	echo "kubectl apply -f ../yaml/fio-pvc.yaml" >> ${TEMP_PACKAGE}/scripts/deploy-ns-${NAMESPACE}.sh
	chmod 700 ${TEMP_PACKAGE}/scripts/deploy-ns-${NAMESPACE}.sh
	

archive-package:
	tar -zcvf ${PACKAGE_NAME} ${TEMP_PACKAGE}/*

clean-package:
	rm -rf temp_package ${PACKAGE_NAME}

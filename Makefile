HELM_VERSION := v3.0.3
HELM_URL     := https://get.helm.sh
HELM_TGZ      = helm-${HELM_VERSION}-linux-amd64.tar.gz
YQ_VERSION   := 2.4.1
YAMLLINT_VERSION := 1.20.0
CHARTS := ecs-cluster objectscale-manager mongoose zookeeper-operator atlas-operator decks kahm srs-gateway dks-testapp fio-test sonobuoy dellemc-license service-pod
DECKSCHARTS := decks kahm srs-gateway dks-testapp dellemc-license service-pod
FLEXCHARTS := ecs-cluster objectscale-manager

# packaging
TEMP_PACKAGE     := temp_package
MANAGER_MANIFEST := objectscale-manager.yaml
KAHM_MANIFEST    := kahm.yaml
DECKS_MANIFEST   := decks.yaml
PACKAGE_NAME     := objectscale-charts-package.tgz
NAMESPACE         = dellemc-objectscale-system
REGISTRY          = objectscale
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

package: create-temp-package create-manifests combine-crds create-vmware-package archive-package
create-temp-package:
	mkdir -p ${TEMP_PACKAGE}

combine-crds:
	cp -R objectscale-manager/crds ${TEMP_PACKAGE}
	cp -R atlas-operator/crds ${TEMP_PACKAGE}
	cp -R zookeeper-operator/crds ${TEMP_PACKAGE}
	cp -R kahm/crds ${TEMP_PACKAGE}
	cp -R decks/crds ${TEMP_PACKAGE}
	cat ${TEMP_PACKAGE}/crds/*.yaml > ${TEMP_PACKAGE}/objectscale-crd.yaml
	rm -rf ${TEMP_PACKAGE}/crds

create-vmware-package:
	./vmware_pack.sh

create-manifests: create-manager-manifest create-kahm-manifest create-decks-manifest create-deploy-script

create-manager-manifest:
	helm template objectscale-manager ./objectscale-manager -n ${NAMESPACE} \
	--set global.platform=VMware --set global.watchAllNamespaces=false \
	--set sonobuoy.enabled=false --set global.registry=${REGISTRY} \
	--set global.storageClassName=${STORAGECLASSNAME} \
	-f objectscale-manager/values.yaml >> ${TEMP_PACKAGE}/${MANAGER_MANIFEST}

create-kahm-manifest:
	helm template kahm ./kahm -n ${NAMESPACE} --set global.platform=VMware \
	--set global.watchAllNamespaces=false --set global.registry=${REGISTRY} \
	--set storageClassName=${STORAGECLASSNAME} -f kahm/values.yaml >> ${TEMP_PACKAGE}/${KAHM_MANIFEST}

create-decks-manifest:
	helm template decks ./decks -n ${NAMESPACE} --set global.platform=VMware \
	--set global.watchAllNamespaces=false --set global.registry=${REGISTRY} \
	--set storageClassName=${STORAGECLASSNAME} -f decks/values.yaml >> ${TEMP_PACKAGE}/${DECKS_MANIFEST}

create-deploy-script:
	echo "kubectl apply -f ./objectscale-manager.yaml -f ./decks.yaml -f ./kahm.yaml" > ${TEMP_PACKAGE}/deploy-${NAMESPACE}.sh
	sed -n "/fio-pvc/,/^---/p" temp_package/objectscale-manager.yaml > ${TEMP_PACKAGE}/fio-pvc.yaml
	echo "sleep 1" >> ${TEMP_PACKAGE}/deploy-${NAMESPACE}.sh
	echo "kubectl apply -f ./fio-pvc.yaml" >> ${TEMP_PACKAGE}/deploy-${NAMESPACE}.sh
	chmod 700 ${TEMP_PACKAGE}/deploy-${NAMESPACE}.sh

archive-package:
	tar -zcvf ${PACKAGE_NAME} ${TEMP_PACKAGE}/*

clean-package:
	rm -rf ${TEMP_PACKAGE} ${PACKAGE_NAME}

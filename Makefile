HELM_VERSION := v3.0.3
HELM_URL     := https://get.helm.sh
HELM_TGZ      = helm-${HELM_VERSION}-linux-amd64.tar.gz
YQ_VERSION   := 2.4.1
YAMLLINT_VERSION := 1.20.0
CHARTS := ecs-cluster objectscale-manager mongoose zookeeper-operator atlas-operator decks kahm srs-gateway dks-testapp fio-test sonobuoy dellemc-license service-pod objectscale-graphql helm-controller objectscale-vsphere iam
DECKSCHARTS := decks kahm supportassist service-pod dellemc-license
FLEXCHARTS := ecs-cluster objectscale-manager objectscale-vsphere objectscale-graphql helm-controller
MONITORING_DIR := monitoring

# packaging
MANAGER_MANIFEST    := objectscale-manager.yaml
KAHM_MANIFEST       := kahm.yaml
DECKS_MANIFEST      := decks.yaml
PACKAGE_NAME        := objectscale-charts-package.tgz
NAMESPACE            = dellemc-objectscale-system
TEMP_PACKAGE        := temp_package
SERVICE_ID           = objectscale
REGISTRY             = objectscale
DECKS_REGISTRY       = objectscale
KAHM_REGISTRY        = objectscale
STORAGECLASSNAME     = dellemc-objectscale-highly-available

WATCH_ALL_NAMESPACES = false # --set global.watchAllNamespaces={true | false}
HELM_MANAGER_ARGS    = # --set image.tag={YOUR_VERSION_HERE}
HELM_MONITORING_ARGS = # --set global.monitoring.tag=${YOUR_VERSION_HERE}
HELM_UI_ARGS         = # --set image.tag=${YOUR_VERSION_HERE}
HELM_GRAPHQL_ARGS    = # --set objectscale-graphql.tag=${YOUR_VERSION_HERE}
HELM_INSTALLER_ARGS  = # --set objectscale-graphql.helm-controller.tag=${YOUR_VERSION_HERE}
HELM_DECKS_ARGS      = # --set image.tag=${YOUR_VERSION_HERE}
HELM_KAHM_ARGS       = # --set image.tag=${YOUR_VERSION_HERE}

clean: clean-package

test: monitoring-test
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

	echo "looking for yq command"
	which yq
	echo "Found it"
	for CHART in ${DECKSCHARTS}; do  \
		echo "Setting version $$DECKSVER in $$CHART" ;\
		yq w -i $$CHART/Chart.yaml appVersion $${DECKSVER} ; \
		yq w -i $$CHART/Chart.yaml version $${DECKSVER} ; \
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

build-all: monitoring-dep build

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
	./vmware/vmware_pack.sh ${SERVICE_ID}

create-manifests: create-vsphere-install create-kahm-manifest create-decks-manifest create-manager-app

create-vsphere-install: create-vsphere-templates

create-manager-app: create-temp-package
	# cd in makefiles spawns a subshell, so continue the command with ;
	cd objectscale-manager; \
	helm template --show-only templates/objectscale-manager-app.yaml objectscale-manager ../objectscale-manager  -n ${NAMESPACE} \
	--set global.platform=VMware \
	--set sonobuoy.enabled=false \
	--set global.watchAllNamespaces=${WATCH_ALL_NAMESPACES} \
	--set global.registry=${REGISTRY} \
	--set global.storageClassName=${STORAGECLASSNAME} \
	--set logReceiver.create=true --set logReceiver.type=Syslog \
	--set logReceiver.persistence.storageClassName=${STORAGECLASSNAME} \
	--set global.monitoring_registry=${REGISTRY} \
	--set ecs-monitoring.influxdb.persistence.storageClassName=${STORAGECLASSNAME} \
	--set global.monitoring.enabled=false \
	--set iam.enabled=false ${HELM_MANAGER_ARGS} ${HELM_MONITORING_ARGS} \
        --set hooks.storagePolicyHA=${STORAGECLASSNAME} \
	-f values.yaml > ../${TEMP_PACKAGE}/yaml/objectscale-manager-app.yaml;
	sed -i 's/createApplicationResource\\":true/createApplicationResource\\":false/g' ${TEMP_PACKAGE}/yaml/objectscale-manager-app.yaml && \
	sed -i 's/app.kubernetes.io\/managed-by: Helm/app.kubernetes.io\/managed-by: nautilus/g' ${TEMP_PACKAGE}/yaml/objectscale-manager-app.yaml
	cat ${TEMP_PACKAGE}/yaml/objectscale-manager-app.yaml >> ${TEMP_PACKAGE}/yaml/${MANAGER_MANIFEST} && rm ${TEMP_PACKAGE}/yaml/objectscale-manager-app.yaml

create-vsphere-templates: create-temp-package
	helm template vsphere-plugin ./objectscale-vsphere -n ${NAMESPACE} \
	--set global.platform=VMware \
	--set global.watchAllNamespaces=${WATCH_ALL_NAMESPACES} \
    --set graphql.enabled=true \
	--set global.registry=${REGISTRY} \
	--set global.storageClassName=${STORAGECLASSNAME} ${HELM_UI_ARGS} ${HELM_GRAPHQL_ARGS} ${HELM_INSTALLER_ARGS} \
	-f objectscale-vsphere/values.yaml >> ${TEMP_PACKAGE}/yaml/${MANAGER_MANIFEST}

create-kahm-manifest: create-temp-package
	helm template kahm ./kahm -n ${NAMESPACE} --set global.platform=VMware \
	--set global.watchAllNamespaces=${WATCH_ALL_NAMESPACES} --set global.registry=${KAHM_REGISTRY} ${HELM_KAHM_ARGS} \
	--set storageClassName=${STORAGECLASSNAME} -f kahm/values.yaml >> ${TEMP_PACKAGE}/yaml/${KAHM_MANIFEST}
create-decks-manifest: create-temp-package
	helm template decks ./decks -n ${NAMESPACE} --set global.platform=VMware \
	--set global.watchAllNamespaces=${WATCH_ALL_NAMESPACES} --set global.registry=${DECKS_REGISTRY} ${HELM_DECKS_ARGS} \
	--set storageClassName=${STORAGECLASSNAME} -f decks/values.yaml >> ${TEMP_PACKAGE}/yaml/${DECKS_MANIFEST}

archive-package:
	tar -zcvf ${PACKAGE_NAME} ${TEMP_PACKAGE}/*

clean-package:
	rm -rf temp_package ${PACKAGE_NAME}

combine-crd-manager-ci: create-temp-package
	cp -R objectscale-manager/crds ${TEMP_PACKAGE}
	cp -R atlas-operator/crds ${TEMP_PACKAGE}
	cp -R zookeeper-operator/crds ${TEMP_PACKAGE}
	cat ${TEMP_PACKAGE}/crds/*.yaml > ${TEMP_PACKAGE}/yaml/manager-crd.yaml
	rm -rf ${TEMP_PACKAGE}/crds

create-manager-manifest-ci: create-temp-package
	helm template objectscale-manager ./objectscale-manager -n ${NAMESPACE} \
	--set global.platform=Default --set global.watchAllNamespaces=${WATCH_ALL_NAMESPACES} \
	--set sonobuoy.enabled=false --set global.registry=${REGISTRY} \
	--set global.storageClassName=${STORAGECLASSNAME} \
	--set logReceiver.create=false \
	-f objectscale-manager/values.yaml >> ${TEMP_PACKAGE}/yaml/${MANAGER_MANIFEST}

monitoring-test:
	make -C ${MONITORING_DIR} test

monitoring-dep:
	make -C ${MONITORING_DIR} dep

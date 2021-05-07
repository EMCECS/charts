HELM_VERSION := v3.5.3
HELM_URL     := https://get.helm.sh
HELM_TGZ      = helm-${HELM_VERSION}-linux-amd64.tar.gz
YQ_VERSION   := 4.4.1
YAMLLINT_VERSION := 1.20.0
ALL_CHARTS := common-lib ecs-cluster objectscale-manager mongoose zookeeper-operator atlas-operator decks kahm dks-testapp fio-test sonobuoy dellemc-license service-pod helm-controller objectscale-graphql objectscale-vsphere objectscale-portal objectscale-gateway objectscale-iam pravega-operator bookkeeper-operator supportassist decks-support-store statefuldaemonset-operator influxdb-operator federation logging-injector dcm
CHARTS = ${ALL_CHARTS}
DECKSCHARTS := decks kahm supportassist service-pod dellemc-license decks-support-store
FLEXCHARTS := common-lib ecs-cluster objectscale-manager objectscale-vsphere objectscale-graphql helm-controller objectscale-portal objectscale-gateway objectscale-iam statefuldaemonset-operator influxdb-operator federation logging-injector dcm

# release version
MAJOR=0
MINOR=72
PATCH=0
PRERELEASE=

FULL_PACKAGE_VERSION=${MAJOR}.${MINOR}.${PATCH}$(if $(PRERELEASE),-$(PRERELEASE),)
FLEXVER=${FULL_PACKAGE_VERSION}
DECKSVER=2.${MINOR}.${PATCH}$(if $(PRERELEASE),-$(PRERELEASE),)

GIT_COMMIT_COUNT=$(shell git rev-list HEAD | wc -l)
GIT_COMMIT_ID=$(shell git rev-parse HEAD)
GIT_COMMIT_SHORT_ID=$(shell git rev-parse --short HEAD)
GIT_BRANCH_ID=$(shell git rev-parse --abbrev-ref HEAD)
YQ_CMD_VERSION := $(shell yq --version | awk '{print $$3}')

# packaging
MANAGER_MANIFEST    := objectscale-manager.yaml
KAHM_MANIFEST       := kahm.yaml
DECKS_MANIFEST      := decks.yaml
LOGGING_INJECTOR_MANIFEST := logging-injector.yaml
PACKAGE_NAME        := objectscale-charts-package.tgz
NAMESPACE            = dellemc-objectscale-system
TEMP_PACKAGE        := temp_package
SERVICE_ID           = objectscale
REGISTRY             = REGISTRYTEMPLATE
DECKS_REGISTRY       = REGISTRYTEMPLATE
KAHM_REGISTRY        = REGISTRYTEMPLATE
REGISTRYSECRET       = vsphere-docker-secret
STORAGECLASSNAME     = dellemc-${SERVICE_ID}-highly-available
STORAGECLASSNAME_VSAN_SNA     = dellemc-${SERVICE_ID}-vsan-sna-thick
VERSION_SLICE_PATH   = version_slice.json

WATCH_ALL_NAMESPACES = false # --set global.watchAllNamespaces={true | false}
HELM_MANAGER_ARGS    = # --set image.tag={YOUR_VERSION_HERE}
HELM_MONITORING_ARGS = # --set global.monitoring.tag=${YOUR_VERSION_HERE}
HELM_UI_ARGS         = # --set image.tag=${YOUR_VERSION_HERE}
HELM_GRAPHQL_ARGS    = # --set objectscale-graphql.tag=${YOUR_VERSION_HERE}
HELM_INSTALLER_ARGS  = # --set objectscale-graphql.helm-controller.tag=${YOUR_VERSION_HERE}
HELM_DECKS_ARGS      = # --set image.tag=${YOUR_VERSION_HERE}
HELM_KAHM_ARGS       = # --set image.tag=${YOUR_VERSION_HERE}
HELM_DECKS_SUPPORT_STORE_ARGS      = # --set decks-support-store.image.tag=${YOUR_VERSION_HERE}
SED_INPLACE         := -i

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	SED_INPLACE += .orig
endif

ISSUE_EVENTS_RAW     = ${TEMP_PACKAGE}/yaml/issues_events_${FLEXVER}.yaml
ISSUE_EVENTS_REPORT  = ${TEMP_PACKAGE}/yaml/issues_events_${FLEXVER}.json

clean: clean-package

all: test package

release: decksver flexver build generate-issues-events-all add-to-git

resolve-and-release: decksver flexver resolve-versions build generate-issues-events-all add-to-git

test:
	helm version
	yamllint --version
	helm lint ${CHARTS} --set product=objectscale --set global.product=objectscale
	yamllint -c .yamllint.yml */Chart.yaml */values.yaml
	yamllint -c .yamllint.yml -s .yamllint.yml .travis.yml
	helm unittest ${CHARTS}

dep:
	wget -q ${HELM_URL}/${HELM_TGZ}
	tar xzf ${HELM_TGZ} -C /tmp --strip-components=1
	PATH=`pwd`/linux-amd64/:${PATH}
	chmod +x /tmp/helm
	helm plugin list | grep -q "unittest" ; \
	if [ "$${?}" -eq "1" ] ; then \
		helm plugin install https://github.com/lrills/helm-unittest ; \
 	fi
	export PATH=/tmp:$PATH
	sudo pip install yamllint=="${YAMLLINT_VERSION}"
	wget -q http://asdrepo.isus.emc.com/artifactory/objectscale-build/com/github/yq/v${YQ_VERSION}/yq_linux_amd64
	sudo mv yq_linux_amd64 /usr/bin/yq
	sudo chmod u+x /usr/bin/yq

yqcheck:
ifneq (${YQ_VERSION},${YQ_CMD_VERSION})
	@echo "Requires yq version:${YQ_VERSION} found version:${YQ_CMD_VERSION}"
	@echo
	@echo "Run make dep to install 'yq'"
	@echo
	exit 1
endif

decksver: yqcheck
	if [ -z ${DECKSVER} ] ; then \
		echo "Missing DECKSVER= param" ; \
		exit 1 ; \
	fi

	for CHART in ${DECKSCHARTS}; do  \
		echo "Setting version ${DECKSVER} in $$CHART" ;\
		yq e '.appVersion = "${DECKSVER}"' -i $$CHART/Chart.yaml ; \
		yq e '.version = "${DECKSVER}"' -i $$CHART/Chart.yaml ; \
		sed ${SED_INPLACE} '1s/^/---\n/' $$CHART/Chart.yaml ; \
		sed ${SED_INPLACE} -e "0,/^tag.*/s//tag: ${DECKSVER}/"  $$CHART/values.yaml; \
	done ;

	for CHART in ${FLEXCHARTS} ${DECKSCHARTS}; do  \
		echo "Setting decks dep version ${DECKSVER} in $$CHART" ;\
		sed ${SED_INPLACE} -e "/no_auto_change__decks_auto_change/s/version:.*/version: ${DECKSVER} # no_auto_change__decks_auto_change/g"  $$CHART/Chart.yaml; \
		sed ${SED_INPLACE} -e "/no_auto_change__flex_auto_change/s/version:.*/version: ${FLEXVER} # no_auto_change__flex_auto_change/g"  $$CHART/Chart.yaml; \
	done ;

graphqlver: yqcheck
	yq e '(.objectStoreAvailableVersions[0] = "${FLEXVER}") | (.decks.licenseChartVersion = "${DECKSVER}") | (.decks.supportAssistChartVersion = "${DECKSVER}") ' -i objectscale-graphql/values.yaml
	sed ${SED_INPLACE} '1s/^/---\n/' objectscale-graphql/values.yaml
	yamllint -c .yamllint.yml objectscale-graphql/values.yaml

flexver: yqcheck graphqlver
	if [ -z ${FLEXVER} ] ; then \
		echo "Missing FLEXVER= param" ; \
		exit 1 ; \
	fi
	for CHART in ${FLEXCHARTS}; do  \
		echo "Setting version $$FLEXVER in $$CHART" ;\
		yq e '.appVersion = "${FLEXVER}"' -i $$CHART/Chart.yaml ; \
		sed ${SED_INPLACE} -e "/no_auto_change/!s/version:.*/version: ${FLEXVER}/g"  $$CHART/Chart.yaml; \
		sed ${SED_INPLACE} '1s/^/---\n/' $$CHART/Chart.yaml ; \
		sed ${SED_INPLACE} -e "0,/^tag.*/s//tag: ${FLEXVER}/"  $$CHART/values.yaml; \
	done ;


resolve-versions:
	python tools/build_helper/version_resolver.py -vs ${VERSION_SLICE_PATH}


build: yqcheck
	REINDEX=0; \
	if [ "$${CHARTS}" == "$${ALL_CHARTS}" ] ; then \
	    BUILD_CHARTS=`python tools/build_helper/sort_charts_by_deps.py -c ${CHARTS}`; \
	else  \
	    BUILD_CHARTS=`python tools/build_helper/sort_charts_by_deps.py -c ${ALL_CHARTS} -s ${CHARTS}`; \
	fi ; \
	for CHART in $${BUILD_CHARTS}; do \
		CURRENT_VER=`yq e .version $$CHART/Chart.yaml` ; \
		yq e ".entries.$${CHART}[].version" docs/index.yaml | grep -q "\- $${CURRENT_VER}$$" ; \
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

add-to-git:
	for CHART in ${CHARTS}; do \
		if [ -d "$${CHART}/charts" ]; then \
			echo "Adding charts to git for $${CHART}" ; \
			git add $${CHART}/charts; \
		fi; \
	done ; \
	echo "Adding docs to git" ; \
	git add docs; \

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
	cp -R statefuldaemonset-operator/crds ${TEMP_PACKAGE}
	cp -R influxdb-operator/crds ${TEMP_PACKAGE}
	cat ${TEMP_PACKAGE}/crds/*.yaml > ${TEMP_PACKAGE}/yaml/objectscale-crd.yaml
	## Remove # from crd to prevent app-platform from crashing in 7.0P1
	sed ${SED_INPLACE} "/^#.*/d" ${TEMP_PACKAGE}/yaml/objectscale-crd.yaml
	rm -rf ${TEMP_PACKAGE}/crds

create-vmware-package:
	./vmware/vmware_pack.sh ${SERVICE_ID}

create-manifests: create-vsphere-install create-kahm-app create-decks-app create-manager-app create-logging-injector-app

create-vsphere-install: create-vsphere-templates

create-manager-app: create-temp-package
	# cd in makefiles spawns a subshell, so continue the command with ;
	#
	# Run helm template with monitoring.enabled=false to not pollute
	# nautilus.dellemc.com/chart-values of objectscale-manager with tons of default values
	# from child charts. After that replace this value by sed.
	cd objectscale-manager; \
	helm template --show-only templates/objectscale-manager-app.yaml objectscale-manager ../objectscale-manager  -n ${NAMESPACE} \
	--set global.platform=VMware \
	--set global.watchAllNamespaces=${WATCH_ALL_NAMESPACES} \
	--set global.registry=${REGISTRY} \
	--set hooks.registry=${REGISTRY} \
	--set global.registrySecret=${REGISTRYSECRET} \
	--set global.storageClassName=${STORAGECLASSNAME} \
	--set global.monitoring_registry=${REGISTRY} \
	--set ecs-monitoring.influxdb.persistence.storageClassName=${STORAGECLASSNAME} \
	--set global.monitoring.enabled=false \
	--set objectscale-monitoring.influxdb.persistence.storageClassName=${STORAGECLASSNAME} \
	--set objectscale-monitoring.rsyslog.persistence.storageClassName=${STORAGECLASSNAME_VSAN_SNA} \
	--set objectscale-gateway.enabled=false ${HELM_MANAGER_ARGS} ${HELM_MONITORING_ARGS} \
	--set objectscale-iam.enabled=true ${HELM_MANAGER_ARGS} ${HELM_MONITORING_ARGS} \
	--set federation.enabled=true ${HELM_MANAGER_ARGS} ${HELM_MONITORING_ARGS} \
	-f values.yaml > ../${TEMP_PACKAGE}/yaml/objectscale-manager-app.yaml;
	sed ${SED_INPLACE} 's/createApplicationResource\\":true/createApplicationResource\\":false/g' ${TEMP_PACKAGE}/yaml/objectscale-manager-app.yaml && \
	sed ${SED_INPLACE} 's/\\"monitoring\\":{\\"enabled\\":false}/\\"monitoring\\":{\\"enabled\\":true}/g' ${TEMP_PACKAGE}/yaml/objectscale-manager-app.yaml && \
	sed ${SED_INPLACE} 's/app.kubernetes.io\/managed-by: Helm/app.kubernetes.io\/managed-by: nautilus/g' ${TEMP_PACKAGE}/yaml/objectscale-manager-app.yaml
	cat ${TEMP_PACKAGE}/yaml/objectscale-manager-app.yaml >> ${TEMP_PACKAGE}/yaml/${MANAGER_MANIFEST} && rm ${TEMP_PACKAGE}/yaml/objectscale-manager-app.yaml

create-vsphere-templates: create-temp-package
	helm template vsphere-plugin ./objectscale-vsphere -n ${NAMESPACE} \
	--set global.platform=VMware \
	--set global.watchAllNamespaces=${WATCH_ALL_NAMESPACES} \
    --set graphql.enabled=true \
	--set global.registry=${REGISTRY} \
	--set global.registrySecret=${REGISTRYSECRET} \
	--set global.storageClassName=${STORAGECLASSNAME} ${HELM_UI_ARGS} ${HELM_GRAPHQL_ARGS} ${HELM_INSTALLER_ARGS} \
	-f objectscale-vsphere/values.yaml >> ${TEMP_PACKAGE}/yaml/${MANAGER_MANIFEST}

create-decks-app: create-temp-package
	# cd in makefiles spawns a subshell, so continue the command with ;
	cd decks; \
	helm template --show-only templates/decks-app.yaml decks ../decks  -n ${NAMESPACE} \
	--set global.platform=VMware \
	--set global.watchAllNamespaces=${WATCH_ALL_NAMESPACES} \
	--set global.registry=${DECKS_REGISTRY} \
	--set global.registrySecret=${REGISTRYSECRET} \
	--set decks-support-store.persistentVolume.storageClassName=${STORAGECLASSNAME} \
        ${HELM_DECKS_ARGS} ${HELM_DECKS_SUPPORT_STORE_ARGS} \
	-f values.yaml > ../${TEMP_PACKAGE}/yaml/decks-app.yaml;
	sed ${SED_INPLACE} 's/createdecksappResource\\":true/createdecksappResource\\":false/g' ${TEMP_PACKAGE}/yaml/decks-app.yaml && \
	sed ${SED_INPLACE} 's/app.kubernetes.io\/managed-by: Helm/app.kubernetes.io\/managed-by: nautilus/g' ${TEMP_PACKAGE}/yaml/decks-app.yaml
	cat ${TEMP_PACKAGE}/yaml/decks-app.yaml >> ${TEMP_PACKAGE}/yaml/${DECKS_MANIFEST} && rm ${TEMP_PACKAGE}/yaml/decks-app.yaml

create-kahm-app: create-temp-package
	# cd in makefiles spawns a subshell, so continue the command with ;
	cd kahm; \
	helm template --show-only templates/kahm-app.yaml kahm ../kahm  -n ${NAMESPACE} \
	--set global.platform=VMware \
	--set global.watchAllNamespaces=${WATCH_ALL_NAMESPACES} \
	--set global.registry=${KAHM_REGISTRY} \
	--set global.registrySecret=${REGISTRYSECRET} \
	--set storageClassName=${STORAGECLASSNAME} \
        ${HELM_KAHM_ARGS} \
	-f values.yaml > ../${TEMP_PACKAGE}/yaml/kahm-app.yaml;
	sed ${SED_INPLACE} 's/createkahmappResource\\":true/createkahmappResource\\":false/g' ${TEMP_PACKAGE}/yaml/kahm-app.yaml && \
	sed ${SED_INPLACE} 's/app.kubernetes.io\/managed-by: Helm/app.kubernetes.io\/managed-by: nautilus/g' ${TEMP_PACKAGE}/yaml/kahm-app.yaml
	cat ${TEMP_PACKAGE}/yaml/kahm-app.yaml >> ${TEMP_PACKAGE}/yaml/${KAHM_MANIFEST} && rm ${TEMP_PACKAGE}/yaml/kahm-app.yaml

create-logging-injector-app: create-temp-package
	# cd in makefiles spawns a subshell, so continue the command with ;
	cd logging-injector; \
	helm template --show-only templates/logging-injector-app.yaml logging-injector ../logging-injector -n ${NAMESPACE} \
	--set global.watchAllNamespaces=${WATCH_ALL_NAMESPACES} \
	--set global.registry=${REGISTRY} \
	--set global.registrySecret=${REGISTRYSECRET} \
	--set global.objectscale_release_name=objectscale-manager \
	-f values.yaml > ../${TEMP_PACKAGE}/yaml/logging-injector-app.yaml;
	sed ${SED_INPLACE} 's/createApplicationResource\\":true/createApplicationResource\\":false/g' ${TEMP_PACKAGE}/yaml/logging-injector-app.yaml && \
	sed ${SED_INPLACE} 's/app.kubernetes.io\/managed-by: Helm/app.kubernetes.io\/managed-by: nautilus/g' ${TEMP_PACKAGE}/yaml/logging-injector-app.yaml
	cat ${TEMP_PACKAGE}/yaml/logging-injector-app.yaml >> ${TEMP_PACKAGE}/yaml/${LOGGING_INJECTOR_MANIFEST} && rm ${TEMP_PACKAGE}/yaml/logging-injector-app.yaml

archive-package:
	tar -zcvf ${PACKAGE_NAME} ${TEMP_PACKAGE}/*

clean-package:
	rm -rf temp_package ${PACKAGE_NAME}

combine-crd-manager-ci: create-temp-package
	cp -R objectscale-manager/crds ${TEMP_PACKAGE}
	cp -R atlas-operator/crds ${TEMP_PACKAGE}
	cp -R zookeeper-operator/crds ${TEMP_PACKAGE}
	cp -R statefuldaemonset-operator/crds ${TEMP_PACKAGE}
	cp -R influxdb-operator/crds ${TEMP_PACKAGE}
	cat ${TEMP_PACKAGE}/crds/*.yaml > ${TEMP_PACKAGE}/yaml/manager-crd.yaml
	rm -rf ${TEMP_PACKAGE}/crds

create-manager-manifest-ci: create-temp-package
	helm template objectscale-manager ./objectscale-manager -n ${NAMESPACE} \
	--set global.platform=Default --set global.watchAllNamespaces=${WATCH_ALL_NAMESPACES} \
	--set global.registry=${REGISTRY} \
	--set global.registrySecret=${REGISTRYSECRET} \
	--set global.storageClassName=${STORAGECLASSNAME} \
	--set logReceiver.create=false \
	-f objectscale-manager/values.yaml >> ${TEMP_PACKAGE}/yaml/${MANAGER_MANIFEST}

build-installer:
	echo "Copy charts to container and build image"
	docker build -t asdrepo.isus.emc.com:8099/install-controller:${FULL_PACKAGE_VERSION}-$(GIT_COMMIT_COUNT).$(GIT_COMMIT_SHORT_ID) -f ./Dockerfile .
	docker push asdrepo.isus.emc.com:8099/install-controller:${FULL_PACKAGE_VERSION}-$(GIT_COMMIT_COUNT).$(GIT_COMMIT_SHORT_ID)

tag-push-installer:
	docker tag asdrepo.isus.emc.com:8099/install-controller:${FULL_PACKAGE_VERSION}-$(GIT_COMMIT_COUNT).$(GIT_COMMIT_SHORT_ID) asdrepo.isus.emc.com:8099/install-controller:${FULL_PACKAGE_VERSION}
	docker push asdrepo.isus.emc.com:8099/install-controller:${FULL_PACKAGE_VERSION}

generate-issues-events-all:
	mkdir -p ${TEMP_PACKAGE}/yaml

	echo -n > ${ISSUE_EVENTS_RAW}

	for chart in ${FLEXCHARTS}; do  \
		chart_file=$$chart-${FLEXVER}.tgz ; \
		echo "Templating chart $${chart_file}" ;  \
		helm template $$chart docs/$${chart_file} \
			--set product=objectscale --set global.product=objectscale \
			>> ${ISSUE_EVENTS_RAW} ; \
	done ;

	for chart in ${DECKSCHARTS}; do  \
		chart_file=$$chart-${DECKSVER}.tgz ; \
		echo "Templating chart $${chart_file}" ;  \
		helm template $$chart docs/$${chart_file} \
			--set product=objectscale --set global.product=objectscale \
                        --set accessKey=0 --set pin=0 \
                        --set productVersion=0 --set siteID=0 \
			>> ${ISSUE_EVENTS_RAW} ; \
	done ;

	python tools/issues_events_report/issues_events_reporter.py \
		-i ${ISSUE_EVENTS_RAW} -o ${ISSUE_EVENTS_REPORT} -fv ${FLEXVER} -dv ${DECKSVER}

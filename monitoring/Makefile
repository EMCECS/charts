#
# Copyright © [2020] Dell Inc. or its subsidiaries.
# All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc.
# or is licensed to Dell Inc. from third parties. Use of this
# software and the intellectual property contained therein is expressly
# limited to the terms and conditions of the License Agreement under which
# it is provided by or on behalf of Dell Inc. or its subsidiaries.
#
#

GIT_COMMIT_COUNT=$(shell git rev-list HEAD | wc -l)
GIT_COMMIT_ID=$(shell git rev-parse HEAD)
GIT_COMMIT_SHORT_ID=$(shell git rev-parse --short HEAD)
GIT_BRANCH_ID=$(shell git rev-parse --abbrev-ref HEAD)

PACKAGE_VERSION=0.53.0
SERVICE_PACK=0

CHARTS_VERSION=$(PACKAGE_VERSION)+$(GIT_COMMIT_COUNT).$(GIT_COMMIT_SHORT_ID)

MAKEFILE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
# include ${MAKEFILE_DIR}/../../common.mk

CHARTS := cert common-lib fluxd grafana influxdb telegraf telegraf-ds throttler monitoring ecs-monitoring rsyslog rsyslog-client kube-metrics-adapter external-ecs-monitoring telegraf-external-config objectscale-monitoring prometheus-alerts

CHARTS_DIR ?= ./build/charts/

PLATFORM_PKG_ARGS := --values ./monitoring/alerts.yaml

.PHONY: all
all: clean test package

.PHONY: dep
dep:
	for CHART in ${CHARTS}; do \
	    echo "Updating dependency for $$CHART"; \
		helm dependency update $$CHART || exit 1 ; \
	done

.PHONY: test
test: dep
	for CHART in ${CHARTS}; do \
		helm lint $$CHART || exit 1 ; \
		helm unittest $$CHART || exit 1 ; \
		yamllint -c .yamllint.yml -s $$CHART/Chart.yaml $$CHART/values.yaml || exit 1 ; \
	done

.PHONY: package
package: clean dep
	helm package ./monitoring --dependency-update --destination ${CHARTS_DIR} $(PLATFORM_PKG_ARGS) --version ${CHARTS_VERSION}
	helm package ./monitoring --dependency-update --destination ${CHARTS_DIR} $(PLATFORM_PKG_ARGS) --values ./monitoring/profile_pravega.yaml --version ${CHARTS_VERSION}.pravega
	mv ${CHARTS_DIR}/monitoring-${CHARTS_VERSION}.pravega.tgz ${CHARTS_DIR}/pravega-monitoring-${CHARTS_VERSION}.tgz
	helm package ./ecs-monitoring --dependency-update --destination ${CHARTS_DIR} --version ${CHARTS_VERSION}
	helm package ./external-ecs-monitoring --dependency-update --destination ${CHARTS_DIR} --values ./external-ecs-monitoring/alerting_rules.yaml --version ${CHARTS_VERSION}
	helm package ./telegraf-external-config --dependency-update --destination ${CHARTS_DIR} --version ${CHARTS_VERSION}
	helm package ./objectscale-monitoring --dependency-update --destination ${CHARTS_DIR} --version ${CHARTS_VERSION}

.PHONY: clean
clean:
	rm -rf ${CHARTS_DIR}
	rm -rf ./monitoring/charts
	rm -rf ./ecs-monitoring/charts
	rm -rf ./external-ecs-monitoring/charts
	rm -rf ./telegraf-external-config/charts
	rm -rf ./objectscale-monitoring/charts

.PHONY: ver
ver:
	for CHART in ${CHARTS}; do  \
		echo "Setting version ${PACKAGE_VERSION} in $$CHART" ;\
		sed -i -e "/no_auto_change/!s/version:.*/version: ${PACKAGE_VERSION}/g"  $$CHART/Chart.yaml; \
		sed -i -e "/no_auto_change/!s/appVersion:.*/appVersion: ${PACKAGE_VERSION}/g"  $$CHART/Chart.yaml; \
	done ;

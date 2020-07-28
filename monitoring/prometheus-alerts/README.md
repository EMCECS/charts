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

# Prometheus Deployment Chart

Deploy Prometheus Deployment For Alerts.
Single instance is deployed.
Pod consists of Prometheus and Alertmanager containers.

```
helm install prometheus-alerts ./charts/monitoring/prometheus-alerts
```
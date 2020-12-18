# Logging Sidecar Injector Chart

Deploy [mutating webook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) to inject rsyslog client sidecar into pods.

This charts installs [logging-injector](https://eos2git.cec.lab.emc.com/ECS/monitoring/tree/master/k8s/charts/logging-injector) chart from monitoring repository as a dependency and provides config map for install controller.


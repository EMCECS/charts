# Logging Sidecar Injector Chart

Deploy [mutating webook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) to inject rsyslog client sidecar into pods.

Logging injector adds `rsyslog-client` container and `rsyslog-config` volume to the pod spec.
`rsyslog-config` volume mounts ConfigMap `<POD_RELEASE_NAME>-rsyslog-client-config` created by `rsyslog-client` chart.

```
helm install logging-injector ./charts/monitoring/logging-injector
```

## Prerequisites

- Kubernetes 1.15+

## TLS Certificates

Chart uses self-signed CA and server TLS certificates for the webhook service.
CA certificate and private key are pre-generated files in `cert` directory.
Server certificate is generated in the logging injector init container.

## How to Enable Logging Injection for the Pod
Pod definition should include the labels used by K8S to match pods with webhook:
- `objectscale.dellemc.com/logging-inject: "true"`
- `app.kubernetes.io/namespace: <Pod Namespace>`

Pod definition should include annotation `objectscale.dellemc.com/logging-release-name` with pod release name.
Injection service uses this annotation to find rsyslog client ConfigMap in the pod's namespace.

Pod should create `emptyDir` volume with name `log`. Services inside pod should write logs into this directory.

Example:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
spec:
  template:
      labels:
        objectscale.dellemc.com/logging-inject: "true"
        app.kubernetes.io/namespace: "{{ .Release.Namespace }}"
      annotations:
        objectscale.dellemc.com/logging-release-name: "{{ .Release.Name }}"
    spec:
      containers:
      - name: grafana
        ...
        volumeMounts:
        - name: log
          mountPath: /var/log
      volumes:
      - name: log
        emptyDir: {}
```

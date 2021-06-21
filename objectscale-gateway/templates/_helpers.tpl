{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "objectscaleGateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "objectscaleGateway.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "objectscaleGateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "objectscaleGateway.labels" -}}
helm.sh/chart: {{ include "objectscaleGateway.chart" . }}
{{ include "objectscaleGateway.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "objectscaleGateway.selectorLabels" -}}
app.kubernetes.io/name: {{ include "objectscaleGateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: objectscale-gateway
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "objectscaleGateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "objectscaleGateway.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the address of K8S DNS resolver
*/}}
{{- define "objectscaleGateway.dnsResolver" -}}
{{- if (eq .Values.global.platform "OpenShift") -}}
resolver {{ default "dns-default.openshift-dns.svc.cluster.local" .Values.global.dns}};
{{- else -}}
resolver {{ default "kube-dns.kube-system.svc.cluster.local" .Values.global.dns}};
{{- end -}}
{{- end -}}


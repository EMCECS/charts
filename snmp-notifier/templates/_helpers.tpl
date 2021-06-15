{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "notifier.name" -}}
{{- printf "%s-snmp-notifier" .Values.product | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{/*
Create serviceName for the notifier.
*/}}
{{- define "notifier.serviceName" -}}
{{- printf "%s-%s-snmp-notifier" .Release.Name .Values.product | trunc 63 | trimSuffix "-" -}}
{{- end -}}
Create fullName for the resources.
*/}}
{{- define "notifier.fullName" -}}
{{- printf "%s-%s-snmp-notifier" .Release.Name .Values.product | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "notifier.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "notifier.labels" -}}
app.kubernetes.io/name: {{ include "notifier.fullName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: {{ .Release.Name }}
helm.sh/chart: {{ include "notifier.chart" . }}
product: {{ required "product (e.g. OBJECTSCALE) is required" .Values.product | lower }} 
release: {{.Release.Name}}
app.kubernetes.io/component: {{ required "product (e.g. OBJECTSCALE) is required" .Values.product | lower }}-snmp-notifier
{{- range $key, $value := .Values.global.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "notifier.selectorLabels" -}}
app.kubernetes.io/component: {{ required "product (e.g. OBJECTSCALE) is required" .Values.product | lower }}-snmp-notifier
app.kubernetes.io/name: {{ include "notifier.fullName" . }}
{{- range $key, $value := .Values.global.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}

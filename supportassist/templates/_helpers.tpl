{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "supportassist.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "supportassist.fullname" -}}
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
{{- define "supportassist.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "supportassist.labels" -}}
app.kubernetes.io/name: "supportassist-{{.Values.product}}"
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: {{ .Release.Name }}
helm.sh/chart: {{ include "supportassist.chart" . }}
product: {{.Values.product}}
release: {{.Release.Name}}
{{- range $key, $value := .Values.global.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}

{{/*
Verify that systemMode value is allowed.
*/}}
{{- define "supportassist.systemModeValidate" -}}
  {{- if .Values.systemMode -}}
    {{- $sysModeValue := .Values.systemMode -}}
    {{- if or (eq $sysModeValue "normal") (eq $sysModeValue "maintenance") (eq $sysModeValue "preProd") (eq $sysModeValue "update") -}}
      {{- .Values.systemMode -}}
    {{- end -}}
  {{- else -}}
    {{- default "preProd" .Values.systemMode -}}
    {{- .Values.systemMode -}}
  {{- end -}}
{{- end -}}
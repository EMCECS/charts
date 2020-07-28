{{/*
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
*/}}

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "telegraf.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "telegraf.fullname" -}}
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
{{- define "telegraf.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
  CUSTOM TEMPLATES: This section contains templates that make up the different parts of the telegraf configuration file.
  - global_tags section
  - agent section
*/}}

{{- define "global_tags" -}}
{{- $top := .top -}}
{{- $global_tags := .global_tags -}}
{{- if .global_tags -}}
[global_tags]
  {{- range $key, $val := .global_tags }}
      {{ $key }} = {{ tpl $val $top | quote }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "agent" -}}
[agent]
{{- range $key, $value := . -}}
  {{- $tp := typeOf $value }}
  {{- if eq $tp "string"}}
      {{ $key }} = {{ $value | quote }}
  {{- end }}
  {{- if eq $tp "float64"}}
      {{ $key }} = {{ $value | int64 }}
  {{- end }}
  {{- if eq $tp "int"}}
      {{ $key }} = {{ $value | int64 }}
  {{- end }}
  {{- if eq $tp "bool"}}
      {{ $key }} = {{ $value }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "outputs" -}}
{{- $top := .top -}}
{{- $urls := .urls -}}
{{- $partition := .part -}}
{{- $partitions_count := .part_cnt -}}
{{- range $outputIdx, $configObject := .outputs -}}
    {{- range $output, $config := . -}}

    [[outputs.{{- $output }}]]
      {{- if ne $urls "" }}
      urls = [{{- tpl $urls $top | quote }}]
      {{- end }}
    {{- if $config -}}
    {{- $tp := typeOf $config -}}
    {{- if eq $tp "map[string]interface {}" -}}
        {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "string" }}
      {{ $key }} = {{ tpl $value $top | quote }}
          {{- end }}
          {{- if eq $tp "float64" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "int" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "bool" }}
      {{ $key }} = {{ $value }}
          {{- end }}
          {{- if eq $tp "[]interface {}" }}
      {{ $key }} = [
              {{- $numOut := len $value }}
              {{- $numOut := sub $numOut 1 }}
              {{- range $b, $val := $value }}
                {{- $i := int64 $b }}
                {{- $tp := typeOf $val }}
                {{- if eq $i $numOut }}
                  {{- if eq $tp "string" }}
        {{ tpl $val $top | quote }}
                  {{- end }}
                  {{- if eq $tp "float64" }}
        {{ $val | int64 }}
                  {{- end }}
                {{- else }}
                  {{- if eq $tp "string" }}
        {{ tpl $val $top | quote }},
                  {{- end}}
                  {{- if eq $tp "float64" }}
        {{ $val | int64 }},
                  {{- end }}
                {{- end }}
              {{- end }}
      ]
          {{- end }}
        {{- end }}
      {{- if ne $partitions_count 1 }}
      [outputs.{{ $output }}.hashpass]
        partitionpass = {{ $partition }}
        partitions = {{ $partitions_count }}
      {{- end }}
        {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "map[string]interface {}" }}
      [outputs.{{ $output }}.{{ $key }}]
            {{- range $k, $v := $value }}
              {{- $tps := typeOf $v }}
              {{- if eq $tps "string" }}
        {{ $k }} = {{ tpl $v $top | quote }}
              {{- end }}
              {{- if eq $tps "float64" }}
        {{ $k }} = {{ $v | int64 }}.0
              {{- end }}
              {{- if eq $tps "int64" }}
        {{ $k }} = {{ $v | int64 }}
              {{- end }}
              {{- if eq $tps "bool" }}
        {{ $k }} = {{ $v }}
              {{- end }}
              {{- if eq $tps "[]interface {}"}}
        {{ $k }} = [
                {{- $numOut := len $value }}
                {{- $numOut := sub $numOut 1 }}
                {{- range $b, $val := $v }}
                  {{- $i := int64 $b }}
                  {{- if eq $i $numOut }}
            {{ tpl $val $top | quote }}
                  {{- else }}
            {{ tpl $val $top | quote }},
                  {{- end }}
                {{- end }}
        ]
              {{- end }}
              {{- if eq $tps "map[string]interface {}"}}
        [outputs.{{ $output }}.{{ $key }}.{{ $k }}]
                {{- range $foo, $bar := $v }}
            {{ $foo }} = {{ tpl $bar $top | quote }}
                {{- end }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- end }}
    {{- end }}
    {{- end }}
    {{ end }}
{{- end }}
{{- end -}}

{{- define "inputs" -}}
{{- $top := .top -}}
{{- range $inputIdx, $configObject := .inputs -}}
    {{- range $input, $config := . -}}

    [[inputs.{{- $input }}]]
    {{- if $config -}}
    {{- $tp := typeOf $config -}}
    {{- if eq $tp "map[string]interface {}" -}}
        {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "string" }}
      {{ $key }} = {{ tpl $value $top | quote }}
          {{- end }}
          {{- if eq $tp "float64" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "int" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "bool" }}
      {{ $key }} = {{ $value }}
          {{- end }}
          {{- if eq $tp "[]interface {}" }}
      {{ $key }} = [
              {{- $numOut := len $value }}
              {{- $numOut := sub $numOut 1 }}
              {{- range $b, $val := $value }}
                {{- $i := int64 $b }}
                {{- $tp := typeOf $val }}
                {{- if eq $i $numOut }}
                  {{- if eq $tp "string" }}
        {{ tpl $val $top | quote }}
                  {{- end }}
                  {{- if eq $tp "float64" }}
        {{ $val | int64 }}
                  {{- end }}
                {{- else }}
                  {{- if eq $tp "string" }}
        {{ tpl $val $top | quote }},
                  {{- end}}
                  {{- if eq $tp "float64" }}
        {{ $val | int64 }},
                  {{- end }}
                {{- end }}
              {{- end }}
      ]
          {{- end }}
      {{- end }}
      {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "map[string]interface {}" }}
      [inputs.{{ $input }}.{{ $key }}]
            {{- range $k, $v := $value }}
              {{- $tps := typeOf $v }}
              {{- if eq $tps "string" }}
        {{ $k }} = {{ tpl $v $top | quote }}
              {{- end }}
              {{- if eq $tps "[]interface {}"}}
        {{ $k }} = [
                {{- $numOut := len $value }}
                {{- $numOut := sub $numOut 1 }}
                {{- range $b, $val := $v }}
                  {{- $i := int64 $b }}
                  {{- if eq $i $numOut }}
            {{ tpl $val $top | quote }}
                  {{- else }}
            {{ tpl $val $top | quote }},
                  {{- end }}
                {{- end }}
        ]
              {{- end }}
              {{- if eq $tps "map[string]interface {}"}}
        [inputs.{{ $input }}.{{ $key }}.{{ $k }}]
                {{- range $foo, $bar := $v }}
            {{ $foo }} = {{ tpl $bar $top | quote }}
                {{- end }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- end }}
    {{- end }}
    {{- end }}
    {{ end }}
{{- end }}
{{- end -}}

{{- define "processors" -}}
{{- range $processorIdx, $configObject := . -}}
    {{- range $processor, $config := . -}}

    [[processors.{{- $processor }}]]
    {{- if $config -}}
    {{- $tp := typeOf $config -}}
    {{- if eq $tp "map[string]interface {}" -}}
        {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "string" }}
      {{ $key }} = {{ $value | quote }}
          {{- end }}
          {{- if eq $tp "float64" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "int" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "bool" }}
      {{ $key }} = {{ $value }}
          {{- end }}
          {{- if eq $tp "[]interface {}" }}
      {{ $key }} = [
              {{- $numOut := len $value }}
              {{- $numOut := sub $numOut 1 }}
              {{- range $b, $val := $value }}
                {{- $i := int64 $b }}
                {{- $tp := typeOf $val }}
                {{- if eq $i $numOut }}
                  {{- if eq $tp "string" }}
        {{ $val | quote }}
                  {{- end }}
                  {{- if eq $tp "float64" }}
        {{ $val | int64 }}
                  {{- end }}
                {{- else }}
                  {{- if eq $tp "string" }}
        {{ $val | quote }},
                  {{- end}}
                  {{- if eq $tp "float64" }}
        {{ $val | int64 }},
                  {{- end }}
                {{- end }}
              {{- end }}
      ]
          {{- end }}
          {{- if eq $tp "map[string]interface {}" }}
      [[processors.{{ $processor }}.{{ $key }}]]
            {{- range $k, $v := $value }}
              {{- $tps := typeOf $v }}
              {{- if eq $tps "string" }}
        {{ $k }} = {{ $v | quote }}
              {{- end }}
              {{- if eq $tps "[]interface {}"}}
        {{ $k }} = [
                {{- $numOut := len $value }}
                {{- $numOut := sub $numOut 1 }}
                {{- range $b, $val := $v }}
                  {{- $i := int64 $b }}
                  {{- if eq $i $numOut }}
            {{ $val | quote }}
                  {{- else }}
            {{ $val | quote }},
                  {{- end }}
                {{- end }}
        ]
              {{- end }}
              {{- if eq $tps "map[string]interface {}"}}
        [processors.{{ $processor }}.{{ $key }}.{{ $k }}]
                {{- range $foo, $bar := $v }}
                {{- $tp := typeOf $bar -}}
                {{- if eq $tp "string" }}
            {{ $foo }} = {{ $bar | quote }}
                {{- end }}
                {{- if eq $tp "int" }}
            {{ $foo }} = {{ $bar }}
                {{- end }}
                {{- if eq $tp "float64" }}
            {{ $foo }} = {{ int64 $bar }}
                {{- end }}
                {{- end }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- end }}
    {{- end }}
    {{- end }}
    {{ end }}
{{- end }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "telegraf.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "telegraf.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Common template helpers for Kubecert.
*/}}
{{- define "kubecert.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kubecert.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "kubecert.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

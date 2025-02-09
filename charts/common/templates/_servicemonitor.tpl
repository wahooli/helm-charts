{{- define "common.serviceMonitor" -}}
  {{- if (.Values.serviceMonitor).create -}}
    {{- if or (.Values.serviceMonitor).victoriaMetrics (.Capabilities.APIVersions.Has "operator.victoriametrics.com/v1beta1")  }}
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMServiceScrape
metadata:
  name: {{ default (include "common.helpers.names.fullname" .) .Values.serviceMonitor.name  }}
  labels:
    {{- with .Values.serviceMonitor.labels }}
      {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- include "common.helpers.labels" . | nindent 4 }}
  {{- with .Values.serviceMonitor.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
      {{- with .Values.serviceMonitor.securityContext }}
  attach_metadata:
        {{- toYaml . | nindent 4 }}
      {{- end }}
      {{- with .Values.serviceMonitor.discoveryRole }}
  discoveryRole: {{ toYaml . }}
      {{- end }}
  endpoints:
  {{- include "common.tpl.monitorEndpoint" .Values.serviceMonitor.endpoint | nindent 2 }}
      {{- with .Values.serviceMonitor.jobLabel }}
  jobLabel: {{ toYaml . }}
      {{- end }}
  namespaceSelector:
      {{- if (.Values.serviceMonitor).namespaceSelector }}
        {{- toYaml (.Values.serviceMonitor).namespaceSelector | nindent 4 }}
      {{- else }}
    matchNames:
    - {{ .Release.Namespace }}
      {{- end }}
      {{- with .Values.serviceMonitor.podTargetLabels }}
  podTargetLabels:
        {{- toYaml . | nindent 4 }}
      {{- end }}
      {{- with .Values.serviceMonitor.sampleLimit }}
  sampleLimit: {{ toYaml . }}
      {{- end }}
  selector:
      {{- if (.Values.serviceMonitor).selector }}
        {{- toYaml (.Values.serviceMonitor).selector | nindent 4 }}
      {{- else }}
    matchLabels:
        {{- include "common.helpers.labels.selectorLabels" . | nindent 6 }}
      {{- end }}
      {{- with .Values.serviceMonitor.sampleLimit }}
  seriesLimit: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.targetLabels }}
  targetLabels:
        {{- toYaml . | nindent 4 }}
      {{- end }}
    {{- else if .Capabilities.APIVersions.Has "monitoring.coreos.com/v1" }}
      {{- /* TODO */ -}}
    {{- end }}
  {{- end }}
{{- end }}

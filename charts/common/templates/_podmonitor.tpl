{{- define "common.podMonitor" -}}
  {{- if (.Values.podMonitor).create -}}
    {{- if or (.Values.podMonitor).victoriaMetrics (.Capabilities.APIVersions.Has "operator.victoriametrics.com/v1beta1")  }}
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMPodScrape
metadata:
  name: {{ default (include "common.helpers.names.fullname" .) .Values.podMonitor.name  }}
  labels:
    {{- with .Values.podMonitor.labels }}
      {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- include "common.helpers.labels" . | nindent 4 }}
  {{- with .Values.podMonitor.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
      {{- with .Values.podMonitor.securityContext }}
  attach_metadata:
        {{- toYaml . | nindent 4 }}
      {{- end }}
  podMetricsEndpoints:
  {{- include "common.tpl.monitorEndpoint" .Values.podMonitor.endpoint | nindent 2 }}
      {{- with .Values.podMonitor.jobLabel }}
  jobLabel: {{ toYaml . }}
      {{- end }}
  namespaceSelector:
      {{- if (.Values.podMonitor).namespaceSelector }}
        {{- toYaml (.Values.podMonitor).namespaceSelector | nindent 4 }}
      {{- else }}
    matchNames:
    - {{ .Release.Namespace }}
      {{- end }}
      {{- with .Values.podMonitor.podTargetLabels }}
  podTargetLabels:
        {{- toYaml . | nindent 4 }}
      {{- end }}
      {{- with .Values.podMonitor.sampleLimit }}
  sampleLimit: {{ toYaml . }}
      {{- end }}
  selector:
      {{- if (.Values.podMonitor).selector }}
        {{- toYaml (.Values.podMonitor).selector | nindent 4 }}
      {{- else }}
    matchLabels:
        {{- include "common.helpers.labels.podLabels" . | nindent 6 }}
      {{- end }}
      {{- with .Values.podMonitor.sampleLimit }}
  seriesLimit: {{ toYaml . }}
      {{- end }}
    {{- else if .Capabilities.APIVersions.Has "monitoring.coreos.com/v1" }}
      {{- /* TODO */ -}}
    {{- end }}
  {{- end }}
{{- end }}

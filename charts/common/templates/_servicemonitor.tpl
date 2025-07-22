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
      {{- with .Values.serviceMonitor.attachMetadata }}
  attach_metadata:
        {{- toYaml . | nindent 4 }}
      {{- end }}
      {{- with .Values.serviceMonitor.discoveryRole }}
  discoveryRole: {{ toYaml . }}
      {{- end }}
  endpoints:
      {{- if .Values.serviceMonitor.endpoints -}}
        {{- range $_, $endpoint := .Values.serviceMonitor.endpoints }}
          {{- include "common.tpl.monitor.endpoint" (list $endpoint) | nindent 2 }}
        {{- end -}}
      {{- else -}}
        {{- include "common.tpl.monitor.endpoint" (list .Values.serviceMonitor.endpoint) | nindent 2 }}
      {{- end -}}
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
    {{- else if or (and (hasKey (.Values).serviceMonitor "victoriaMetrics") (not .Values.serviceMonitor.victoriaMetrics) ) (.Capabilities.APIVersions.Has "monitoring.coreos.com/v1") }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
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
      {{- with .Values.serviceMonitor.attachMetadata }}
  attachMetadata:
        {{- toYaml . | nindent 4 }}
      {{- end }}
  endpoints:
      {{- if .Values.serviceMonitor.endpoints -}}
        {{- range $_, $endpoint := .Values.serviceMonitor.endpoints }}
          {{- include "common.tpl.monitor.endpoint" (list $endpoint false) | nindent 2 }}
        {{- end -}}
      {{- else -}}
        {{- include "common.tpl.monitor.endpoint" (list .Values.serviceMonitor.endpoint false) | nindent 2 }}
      {{- end -}}
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
        {{- include "common.helpers.labels.podLabels" . | nindent 6 }}
      {{- end }}
      {{- with .Values.serviceMonitor.selectorMechanism }}
  selectorMechanism: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.targetLimit }}
  targetLimit: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.scrapeProtocols }}
  scrapeProtocols:
        {{- toYaml . | nindent 2 }}
      {{- end }}
      {{- with .Values.serviceMonitor.fallbackScrapeProtocol }}
  fallbackScrapeProtocol: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.labelLimit }}
  labelLimit: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.labelNameLengthLimit }}
  labelNameLengthLimit: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.labelValueLengthLimit }}
  labelValueLengthLimit: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.scrapeClassicHistograms }}
  scrapeClassicHistograms: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.nativeHistogramBucketLimit }}
  nativeHistogramBucketLimit: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.nativeHistogramMinBucketFactor }}
  nativeHistogramMinBucketFactor: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.convertClassicHistogramsToNHCB }}
  convertClassicHistogramsToNHCB: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.keepDroppedTargets }}
  keepDroppedTargets: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.scrapeClass }}
  scrapeClass: {{ toYaml . }}
      {{- end }}
      {{- with .Values.serviceMonitor.scrapeClassibodySizeLimitcHistograms }}
  bodySizeLimit: {{ toYaml . }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

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
      {{- with .Values.podMonitor.attachMetadata }}
  attach_metadata:
        {{- toYaml . | nindent 4 }}
      {{- end }}
  podMetricsEndpoints:
      {{- if .Values.podMonitor.endpoints -}}
        {{- range $_, $endpoint := .Values.podMonitor.endpoints }}
          {{- include "common.tpl.monitor.endpoint" (list $endpoint) | nindent 2 }}
        {{- end -}}
      {{- else -}}
        {{- include "common.tpl.monitor.endpoint" (list .Values.podMonitor.endpoint) | nindent 2 }}
      {{- end -}}
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
      {{- with .Values.podMonitor.seriesLimit }}
  seriesLimit: {{ toYaml . }}
      {{- end }}
    {{- else if or (and (hasKey (.Values).podMonitor "victoriaMetrics") (not .Values.podMonitor.victoriaMetrics) ) (.Capabilities.APIVersions.Has "monitoring.coreos.com/v1") }}
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
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
      {{- with .Values.podMonitor.attachMetadata }}
  attachMetadata:
        {{- toYaml . | nindent 4 }}
      {{- end }}
  podMetricsEndpoints:
      {{- if .Values.podMonitor.endpoints -}}
        {{- range $_, $endpoint := .Values.podMonitor.endpoints }}
          {{- include "common.tpl.monitor.endpoint" (list $endpoint false true) | nindent 2 }}
        {{- end -}}
      {{- else -}}
        {{- include "common.tpl.monitor.endpoint" (list .Values.podMonitor.endpoint false true) | nindent 2 }}
      {{- end -}}
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
      {{- with .Values.podMonitor.selectorMechanism }}
  selectorMechanism: {{ toYaml . }}
      {{- end }}
      {{- with .Values.podMonitor.targetLimit }}
  targetLimit: {{ toYaml . }}
      {{- end }}
      {{- with .Values.podMonitor.scrapeProtocols }}
  scrapeProtocols:
        {{- toYaml . | nindent 2 }}
      {{- end }}
      {{- with .Values.podMonitor.fallbackScrapeProtocol }}
  fallbackScrapeProtocol: {{ toYaml . }}
      {{- end }}
      {{- with .Values.podMonitor.labelLimit }}
  labelLimit: {{ toYaml . }}
      {{- end }}
      {{- with .Values.podMonitor.labelNameLengthLimit }}
  labelNameLengthLimit: {{ toYaml . }}
      {{- end }}
      {{- with .Values.podMonitor.labelValueLengthLimit }}
  labelValueLengthLimit: {{ toYaml . }}
      {{- end }}
      {{- with .Values.podMonitor.scrapeClassicHistograms }}
  scrapeClassicHistograms: {{ toYaml . }}
      {{- end }}
      {{- with .Values.podMonitor.nativeHistogramBucketLimit }}
  nativeHistogramBucketLimit: {{ toYaml . }}
      {{- end }}
      {{- with .Values.podMonitor.nativeHistogramMinBucketFactor }}
  nativeHistogramMinBucketFactor: {{ toYaml . }}
      {{- end }}
      {{- with .Values.podMonitor.convertClassicHistogramsToNHCB }}
  convertClassicHistogramsToNHCB: {{ toYaml . }}
      {{- end }}
      {{- with .Values.podMonitor.keepDroppedTargets }}
  keepDroppedTargets: {{ toYaml . }}
      {{- end }}
      {{- with .Values.podMonitor.scrapeClass }}
  scrapeClass: {{ toYaml . }}
      {{- end }}
      {{- with .Values.podMonitor.scrapeClassibodySizeLimitcHistograms }}
  bodySizeLimit: {{ toYaml . }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Selector labels */}}
{{- define "common.helpers.labels.selectorLabels" -}}
{{- $root := $ -}}
app.kubernetes.io/name: {{ include "common.helpers.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if or (.Values.global).selectorLabels .Values.selectorLabels -}}
  {{- $extraSelectorLabels := (.Values.global).selectorLabels | default .Values.selectorLabels -}}
  {{- range $label, $labelValue := $extraSelectorLabels -}}
    {{- (tpl ($label | toString) $root) | nindent 0 -}}: {{ (tpl ($labelValue | toString) $root) }}
  {{- end }}
{{- end -}}
{{- end }}

{{/* Common labels */}}
{{- define "common.helpers.labels" -}}
helm.sh/chart: {{ include "common.helpers.names.chart" . }}
{{ include "common.helpers.labels.selectorLabels" . }}
  {{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
  {{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
  {{- with (.Values.global).labels }}
    {{- range $k, $v := . }}
      {{- $name := $k }}
      {{- $value := tpl $v $ }}
{{ $name }}: {{ quote $value }}
    {{- end }}
  {{- end }}
{{- end }}


{{- define "common.helpers.labels.podLabels" -}}
  {{- include "common.helpers.labels.selectorLabels" . }}
  {{- with (.Values.global).labels }}
    {{- range $k, $v := . }}
      {{- $name := $k }}
      {{- $value := tpl $v $ }}
{{ $name }}: {{ quote $value }}
    {{- end }}
  {{- end }}
{{- end }}
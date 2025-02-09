{{/*
usage: {{ include "common.tpl.monitorEndpoint" [endpoint spec] }}
*/}}
{{- define "common.tpl.monitorEndpoint" }}
{{- $port := .targetPort | default .port -}}
{{- $scrapeInterval := .scrape_interval | default .interval -}}
{{- if not $port -}}
  {{- fail "Service or Pod monitor requires target port, defined by 'targetPort' or 'port' value!" -}}
{{- end -}}
- targetPort: {{ .targetPort | default .port }}

{{- with .path }}
  path: {{ toYaml . }}
{{- end -}}

{{- with .attach_metadata }}
  attach_metadata:
  {{- toYaml . | nindent 4 }}
{{- end -}}

{{- with .authorization }}
  authorization:
  {{- toYaml . | nindent 4 }}
{{- end -}}

{{- with .basicAuth }}
  basicAuth:
  {{- toYaml . | nindent 4 }}
{{- end -}}

{{- with .bearerTokenFile }}
  bearerTokenFile: {{ toYaml . }}
{{- end -}}

{{- with .bearerTokenSecret }}
  bearerTokenSecret:
  {{- toYaml . | nindent 4 }}
{{- end -}}

{{- /* valid only for VMPodScrape */ -}}
{{- with .filterRunning }}
  filterRunning: {{ toYaml . }}
{{- end -}}

{{- with .follow_redirects }}
  follow_redirects: {{ toYaml . }}
{{- end -}}

{{- with .honorLabels }}
  honorLabels: {{ toYaml . }}
{{- end -}}

{{- with .honorTimestamps }}
  honorTimestamps: {{ toYaml . }}
{{- end -}}

{{- with .max_scrape_size }}
  max_scrape_size: {{ toYaml . }}
{{- end -}}

{{- with .metricRelabelConfigs }}
  metricRelabelConfigs:
  {{- toYaml . | nindent 2 }}
{{- end -}}

{{- with .oauth2 }}
  oauth2:
  {{- toYaml . | nindent 4 }}
{{- end -}}

{{- with .params }}
  params:
  {{- toYaml . | nindent 4 }}
{{- end -}}

{{- with .proxyURL }}
  proxyURL: {{ toYaml . }}
{{- end -}}

{{- with .relabelConfigs }}
  relabelConfigs:
  {{- toYaml . | nindent 2 }}
{{- end -}}

{{- with .sampleLimit }}
  sampleLimit: {{ toYaml . }}
{{- end -}}

{{- with .scheme }}
  scheme: {{ toYaml . }}
{{- end -}}

{{- with .scrapeTimeout }}
  scrapeTimeout: {{ toYaml . }}
{{- end -}}

{{- if $scrapeInterval }}
  scrape_interval: {{ toYaml $scrapeInterval }}
{{- end -}}

{{- with .seriesLimit }}
  seriesLimit: {{ toYaml . }}
{{- end -}}

{{- with .tlsConfig }}
  tlsConfig:
  {{- toYaml . | nindent 4 }}
{{- end -}}

{{- with .vm_scrape_params }}
  vm_scrape_params:
  {{- toYaml . | nindent 4 }}
{{- end -}}
{{- end }}

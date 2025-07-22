{{/*
usage: {{ include "common.tpl.monitor.endpoint" (list [endpoint spec] [bool] [bool]) }}
first boolean value defines if monitorEndpoint conforms to VictoriaMetrics spec
second boolean value defines if endpoint should conform directly to PodMonitor spec
*/}}
{{- define "common.tpl.monitor.endpoint" }}
{{- $endpoint := index . 0 -}}
{{- $isVmSpec := true -}}
{{- $isPodMonitor := false -}}
{{- if ge (len .) 2 -}}
  {{- $isVmSpec = index . 1 -}}
{{- end -}}
{{- if ge (len .) 3 -}}
  {{- $isPodMonitor = index . 2 -}}
{{- end -}}
{{- with $endpoint -}}
{{- $port := .targetPort | default .port -}}
{{- $scrapeInterval := .scrape_interval | default .interval -}}
{{- if not $port -}}
  {{- fail "Service or Pod monitor requires target port, defined by 'targetPort' or 'port' value!" -}}
{{- end -}}
{{- if $isVmSpec -}}
- targetPort: {{ .targetPort | default .port }}
{{- else -}}
{{- if kindIs "string" $port -}}
- port: {{ $port | toString }}
{{- else if and $isPodMonitor (or (kindIs "int" $port) (kindIs "float64" $port)) -}}
- portNumber: {{ int $port }}
{{- else if not $isPodMonitor -}}
- targetPort: {{ int $port }}
{{- else if $isPodMonitor -}}
  {{- fail "Service or Pod monitor requires target port, defined by 'targetPort' or 'port' value as string or integer!" -}}
{{- end -}}
{{- end -}}

{{- with .path }}
  path: {{ toYaml . }}
{{- end -}}

{{- if $isVmSpec -}}
{{- with .attachMetadata }}
  attach_metadata:
  {{- toYaml . | nindent 4 }}
{{- end -}}
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

{{- $followRedirectsKey := ternary "follow_redirects" "followRedirects" $isVmSpec -}}
{{- with .followRedirects }}
  {{ $followRedirectsKey }}: {{ toYaml . }}
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

{{- $metricRelabelConfigsKey := ternary "metricRelabelConfigs" "metricRelabelings" $isVmSpec -}}
{{- with .metricRelabelConfigs }}
  {{ $metricRelabelConfigsKey }}:
  {{- include "common.tpl.monitor.relabelConfigs" (list . $isVmSpec) | nindent 2 -}}
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

{{- $relabelConfigsKey := ternary "relabelConfigs" "relabelings" $isVmSpec -}}
{{- with .relabelConfigs }}
  {{ $relabelConfigsKey }}:
  {{- include "common.tpl.monitor.relabelConfigs" (list . $isVmSpec) | nindent 2 -}}
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

{{- $intervalKey := ternary "scrape_interval" "interval" $isVmSpec -}}
{{- if $scrapeInterval }}
  {{ $intervalKey }}: {{ toYaml $scrapeInterval }}
{{- end -}}

{{- with .seriesLimit }}
  seriesLimit: {{ toYaml . }}
{{- end -}}

{{- with .tlsConfig }}
  tlsConfig:
  {{- toYaml . | nindent 4 }}
{{- end -}}

{{- if not $isVmSpec -}}
{{- with .trackTimestampsStaleness }}
  trackTimestampsStaleness: {{- toYaml . }}
{{- end -}}

{{- with .noProxy }}
  noProxy: {{ toYaml . }}
{{- end -}}

{{- with .proxyFromEnvironment }}
  proxyFromEnvironment: {{ toYaml . }}
{{- end -}}

{{- with .enableHttp2 }}
  enableHttp2: {{ toYaml . }}
{{- end -}}

{{- with .proxyConnectHeader }}
  proxyConnectHeader:
  {{- toYaml . | nindent 4 }}
{{- end -}}
{{- end -}}

{{- with .vm_scrape_params }}
  vm_scrape_params:
  {{- toYaml . | nindent 4 }}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
usage: {{ include "common.tpl.monitor.relabelConfigs" (list [relabelConfigs] [bool]]) }}
boolean value defines if monitorEndpoint conforms to VictoriaMetrics spec
*/}}
{{- define "common.tpl.monitor.relabelConfigs" }}
  {{- $relabelConfigs := list -}}
  {{- $isVmSpec := true -}}
  {{- if ge (len .) 2 -}}
    {{- $isVmSpec = index . 1 -}}
  {{- end -}}
  {{- range $config := (index . 0) | default list -}}
    {{- $relabelConfigs = append $relabelConfigs (fromYaml (include "common.tpl.monitor.relabelConfig" (list $config $isVmSpec))) -}}
  {{- end -}}
  {{- toYaml $relabelConfigs -}}
{{- end }}


{{/*
usage: {{ include "common.tpl.monitor.relabelConfigs" (list [relabelConfigs] [bool]]) }}
boolean value defines if monitorEndpoint conforms to VictoriaMetrics spec
*/}}
{{- define "common.tpl.monitor.relabelConfig" }}
  {{- $relabelConfig := index . 0 -}}
  {{- $isVmSpec := true -}}
  {{- if ge (len .) 2 -}}
    {{- $isVmSpec = index . 1 -}}
  {{- end -}}
  {{- if or (hasKey $relabelConfig "source_labels") (hasKey $relabelConfig "sourceLabels") -}}
    {{- $sourceLabels := $relabelConfig.source_labels | default $relabelConfig.sourceLabels -}}
    {{- $relabelConfig = omit $relabelConfig "sourceLabels" "source_labels" -}}
    {{- if $isVmSpec -}}
      {{- $_ := set $relabelConfig "source_labels" $sourceLabels -}}
    {{- else -}}
      {{- $_ := set $relabelConfig "sourceLabels" $sourceLabels -}}
    {{- end -}}
  {{- end -}}
  {{- if or (hasKey $relabelConfig "target_label") (hasKey $relabelConfig "targetLabel") -}}
    {{- $targetLabel := $relabelConfig.target_label | default $relabelConfig.targetLabel -}}
    {{- $relabelConfig = omit $relabelConfig "targetLabel" "target_label" -}}
    {{- if $isVmSpec -}}
      {{- $_ := set $relabelConfig "target_label" $targetLabel -}}
    {{- else -}}
      {{- $_ := set $relabelConfig "targetLabel" $targetLabel -}}
    {{- end -}}
  {{- end -}}
  {{- if not $isVmSpec -}}
    {{- $relabelConfig = omit $relabelConfig "match" "labels" "if" -}}
  {{- end -}}
  {{- toYaml $relabelConfig -}}
{{- end }}
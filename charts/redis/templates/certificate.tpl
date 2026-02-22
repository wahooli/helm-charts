{{- if (.Values.ssl).enabled -}}
  {{- $ctx := deepCopy . -}}
  {{- $_ := include "redis.certificateValues" . | fromYaml | merge $ctx.Values -}}
  {{- include "common.certificate" $ctx }}
{{- end }}

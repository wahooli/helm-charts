{{- if (.Values.ssl).enabled }}
  {{- $ctx := deepCopy . -}}
  {{- $_ := include "patroni.certificateValues" . | fromYaml | merge $ctx.Values -}}
  {{- include "common.certificate" $ctx }}
{{- end }}

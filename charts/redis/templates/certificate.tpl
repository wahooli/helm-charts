{{- $ctx := deepCopy . -}}
{{- $_ := include "redis.certificateValues" . | fromYaml | merge $ctx.Values -}}
{{ include "common.certificate" $ctx }}

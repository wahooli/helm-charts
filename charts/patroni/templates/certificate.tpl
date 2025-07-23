{{- $ctx := deepCopy . -}}
{{- $_ := include "patroni.certificateValues" . | fromYaml | merge $ctx.Values -}}
{{ include "common.certificate" $ctx }}

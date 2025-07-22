{{- $ctx := deepCopy . -}}
{{- $_ := include "etcd.certificateValues" . | fromYaml | merge $ctx.Values -}}
{{ include "common.certificate" $ctx }}

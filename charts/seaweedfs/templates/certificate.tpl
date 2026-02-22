{{- $ctx := deepCopy . -}}
{{- $_ := include "seaweedfs.certificateValues" . | fromYaml | merge $ctx.Values -}}
{{ include "common.certificate" $ctx }}

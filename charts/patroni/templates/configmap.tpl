{{- $ctx := deepCopy . -}}
{{- $_ := include "patroni.configMapValues" . | fromYaml | merge $ctx.Values -}}
{{ include "common.configMap" $ctx }}
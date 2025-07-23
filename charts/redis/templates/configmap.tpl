{{- $ctx := deepCopy . -}}
{{- $_ := include "redis.configMapValues" . | fromYaml | merge $ctx.Values -}}
{{ include "common.configMap" $ctx }}
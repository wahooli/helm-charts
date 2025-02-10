{{- $ctx := deepCopy . -}}
{{- $_ := unset $ctx.Values "configMaps" -}}
{{- $_ := include "bazarr.configMapValues" . | fromYaml | merge $ctx.Values -}}
{{ include "common.configMap" $ctx }}

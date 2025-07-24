{{- $ctx := deepCopy . -}}
{{- $_ := unset $ctx.Values "configMaps" -}}
{{- $_ := include "plex.configMapValues" . | fromYaml | merge $ctx.Values -}}
{{ include "common.configMap" $ctx }}

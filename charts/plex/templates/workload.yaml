{{- $ctx := deepCopy . -}}
{{- $_ := unset $ctx.Values "configMaps" -}}
{{- $_ := include "plex.workloadValues" . | fromYaml | merge $ctx.Values -}}
{{ include "common.workload" $ctx }}

{{- $ctx := deepCopy . -}}
{{- $_ := unset $ctx.Values "configMaps" -}}
{{- $_ := include "sonarr.workloadValues" . | fromYaml | merge $ctx.Values -}}
{{ include "common.workload" $ctx }}

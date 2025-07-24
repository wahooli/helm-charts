{{- $ctx := deepCopy . -}}
{{- $_ := unset $ctx.Values "configMaps" -}}
{{- $_ := include "prowlarr.workloadValues" . | fromYaml | merge $ctx.Values -}}
{{ include "common.workload" $ctx }}

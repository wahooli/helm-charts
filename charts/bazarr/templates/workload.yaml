{{- $ctx := deepCopy . -}}
{{- $_ := unset $ctx.Values "configMaps" -}}
{{- $_ := include "bazarr.workloadValues" . | fromYaml | merge $ctx.Values -}}
{{ include "common.workload" $ctx }}

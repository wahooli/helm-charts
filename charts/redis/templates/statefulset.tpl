{{- $ctx := deepCopy . -}}
{{- $stsVals := include "redis.stsValues" . | fromYaml -}}
{{- $values := get $ctx "Values" -}}
{{- if $stsVals.command -}}
  {{- $values = omit $values "command" -}}
{{- end -}}
{{- if $stsVals.probe -}}
  {{- $values = omit $values "probe" -}}
{{- end -}}
{{- if ($stsVals).service -}}
  {{- $service := get $values "service" -}}
  {{- if ($stsVals.service.main).ports -}}
    {{- $mainService := get $service "main" -}}
    {{- $mainService = omit $mainService "ports" -}}
    {{- $_ := set $service "main" $mainService -}}
  {{- end -}}
  {{- if ($stsVals.service.sentinel).ports -}}
    {{- $sentinelService := get $service "sentinel" -}}
    {{- $sentinelService = omit $sentinelService "ports" -}}
    {{- $_ := set $service "sentinel" $sentinelService -}}
  {{- end -}}
  {{- $_ := set $values "service" $service -}}
{{- end -}}
{{- $_ := set $ctx "Values" $values -}}
{{- $_ := $stsVals | merge $ctx.Values -}}
{{ include "common.statefulset" $ctx }}
{{- $ctx := deepCopy . -}}
{{- $serviceVals := include "redis.serviceValues" . | fromYaml -}}
{{- if ($serviceVals.service.main).ports -}}
  {{- $values := get $ctx "Values" -}}
  {{- $service := get $values "service" -}}
  {{- $mainService := get $service "main" -}}
  {{- $mainService = omit $mainService "ports" -}}
  {{- $_ := set $service "main" $mainService -}}
  {{- $_ := set $ctx "Values" $values -}}
{{- end -}}
{{- $_ := $serviceVals | merge $ctx.Values -}}
{{ include "common.service" $ctx }}

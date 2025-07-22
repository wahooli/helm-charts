{{- $ctx := deepCopy . -}}
{{- $stsVals := include "etcd.stsValues" . | fromYaml -}}
{{- $_ := $stsVals | merge $ctx.Values -}}
{{- if $stsVals.args -}}
  {{- $values := omit $ctx.Values "args" -}}
  {{- $_ := set $values "args" (concat $ctx.Values.args $stsVals.args) -}}
  {{- $_ := set $ctx "Values" $values -}}
{{- end -}}
{{- if $ctx.Values.extraArgs -}}
  {{- $values := omit $ctx.Values "args" -}}
  {{- $_ := set $values "args" (concat $ctx.Values.args $ctx.Values.extraArgs) -}}
  {{- $_ := set $ctx "Values" $values -}}
{{- end -}}
{{ include "common.statefulset" $ctx }}

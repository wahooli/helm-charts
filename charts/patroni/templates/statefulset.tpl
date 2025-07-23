{{- $ctx := deepCopy . -}}
{{- $stsVals := include "patroni.stsValues" . | fromYaml -}}

{{- if $stsVals.args -}}
  {{- $values := omit $ctx.Values "args" -}}
  {{- $_ := set $ctx "Values" $values -}}
{{- end -}}
{{- if and $stsVals.containers (hasKey $stsVals.containers "postgres-exporter") (index $stsVals.containers "postgres-exporter").args -}}
  {{- $pgExporter := get $ctx.Values.containers "postgres-exporter" -}}
  {{- $pgExporter = omit $pgExporter "args" -}}
  {{- $_ := set $ctx.Values.containers "postgres-exporter" $pgExporter -}}
{{- end -}}
{{- if and $stsVals.containers (hasKey $stsVals.containers "pgbouncer-exporter") (index $stsVals.containers "pgbouncer-exporter").args -}}
  {{- $pgBouncerExporter := get $ctx.Values.containers "pgbouncer-exporter" -}}
  {{- $pgBouncerExporter = omit $pgBouncerExporter "args" -}}
  {{- $_ := set $ctx.Values.containers "pgbouncer-exporter" $pgBouncerExporter -}}
{{- end -}}
{{- $_ := $stsVals | merge $ctx.Values -}}
{{ include "common.statefulset" $ctx }}
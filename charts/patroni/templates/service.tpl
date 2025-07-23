{{- $ctx := omit (deepCopy .) "Values" -}}
{{- $_ := merge $ctx (include "patroni.serviceValues" . | fromYaml) -}}
{{ include "common.service" $ctx }}

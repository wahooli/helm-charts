{{- $ctx := omit (deepCopy .) "Values" -}}
{{- $_ := merge $ctx (include "bazarr.serviceValues" . | fromYaml) -}}
{{ include "common.service" $ctx }}

{{- $ctx := omit (deepCopy .) "Values" -}}
{{- $_ := merge $ctx (include "prowlarr.serviceValues" . | fromYaml) -}}
{{ include "common.service" $ctx }}

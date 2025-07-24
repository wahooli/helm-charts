{{- $ctx := omit (deepCopy .) "Values" -}}
{{- $_ := merge $ctx (include "sonarr.serviceValues" . | fromYaml) -}}
{{ include "common.service" $ctx }}

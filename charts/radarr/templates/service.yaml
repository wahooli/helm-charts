{{- $ctx := omit (deepCopy .) "Values" -}}
{{- $_ := merge $ctx (include "radarr.serviceValues" . | fromYaml) -}}
{{ include "common.service" $ctx }}

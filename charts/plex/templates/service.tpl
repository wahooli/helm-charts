{{- $ctx := omit (deepCopy .) "Values" -}}
{{- $_ := merge $ctx (include "plex.serviceValues" . | fromYaml) -}}
{{ include "common.service" $ctx }}

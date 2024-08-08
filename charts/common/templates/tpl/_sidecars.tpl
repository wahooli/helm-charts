{{- define "common.tpl.sidecars" }}
  {{- $sidecars := list -}}
  {{- range $name, $sidecar := .Values.sidecars -}}
    {{- $sidecars = append $sidecars (merge $sidecar (dict "name" $name)) -}}
  {{- end -}}
  {{- if $sidecars -}}
{{ toYaml $sidecars }}
  {{- end }}
{{- end }}
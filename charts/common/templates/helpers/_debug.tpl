{{- define "common.tpl.debug" -}}
  {{- . | mustToPrettyJson | printf "\nThe JSON output of the dumped var is: \n%s" | fail }}
{{- end }}
